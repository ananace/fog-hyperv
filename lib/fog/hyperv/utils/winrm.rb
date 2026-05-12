# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

# WinRM helper methods
module Fog::Hyperv::Utils::Winrm
  # Struct emulating a WinRM shell return
  LocalExecOutput = Struct.new(:stdout, :stderr, :exitcode)

  # Check if the PowerShell version is newer than the value specified
  # @param version [String] a semver version to check if powershell matches
  # @returns [Boolean] is the running PowerShell newer than the given version
  def ps_version?(version)
    Gem::Version(version) >= Gem::Version("#{ps_version[:major]}.#{ps_version[:minor]}")
  end

  # Run a command on the Hyper-V system
  # @param cmd [String] the PowerShell command to execute
  # @param _skip_json [Boolean] should the return data be returned as-is, instead of being sent as JSON
  # @param _target_computer [String,nil] the computer to execute the command on, in case of clustering
  # @param options [Hash] the options to call the command with
  # @option options [Integer] _json_depth (1) the depth to limit the JSON object to on return
  # @return [Hash] the returned object from PowerShell
  def run_cmd(cmd, _skip_json: false, _target_computer: nil, **options)
    _json_depth = options.delete(:_json_depth) { 1 }

    run_cmdlist([[cmd, options.dup]], skip_json: _skip_json, json_depth: _json_depth, target_computer: _target_computer)
  end

  # Run a list of commands on the Hyper-V system
  # @param commands [Array<Array(String,Hash)>] a list of commands with their arguments to run
  # @param skip_json [Boolean] should the return value be given as-is, instead of being sent as JSON
  # @param target_computer [String,nil] the computer to execute the command on, in case of clustering
  # @param options [Hash] additional options for the call
  # @option options [Integer] json_depth (1) the depth to limit the JSON object to on return
  def run_cmdlist(commands, skip_json: false, target_computer: nil, **options)
    target_computer = [target_computer].flatten.compact
    target_computer << '.' if target_computer.empty?

    json_depth = options.delete(:json_depth) { 1 }

    Fog::Logger.debug "run_cmdlist given unknown meta-arguments: #{options.keys.join ', '}" if options.any?

    out = nil
    target_computer.each do |computer|
      connection(computer).shell(:powershell) do |shell|
        shell.run "$ConfirmPreference = 'None'"
        shell.run "$ErrorActionPreference = 'Stop'"
        shell.run '$PSNativeCommandUseErrorActionPreference = $true'

        commands.each.with_index do |(command, args), idx|
          last = idx == commands.size - 1
          ps_cmd = build_pscall(command, _to_json: last && !skip_json, _json_depth: json_depth, **args)

          ps_cmd.each do |cmd|
            Fog::Logger.debug "PS; >>> #{cmd.inspect}"
            out = shell.run cmd
            Fog::Logger.debug "PS; <<< OUT=[#{out.stdout.inspect}] ERR=[#{out.stderr.inspect}] EXIT=[#{out.exitcode}]"

            is_success = true
            is_success = shell.run('$?').stdout.strip.downcase == 'true' if out.stderr.include? 'FullyQualifiedErrorId'

            raise Fog::Hyperv::Errors::PSError.new(out, "When executing #{cmd}") if
              out.exitcode != 0 || !is_success
          end
        end
      end
    end

    return out if skip_json
    return nil if out.stdout.strip.empty?

    json = Fog::JSON.decode(out.stdout)
    Fog::Hyperv.uncamelize(json)
  end

  # Perform a WQL query against the Hyper-V system
  # @param query [String] the query to perform
  # @param _namespace [String] the namespace to perform the call in
  # @param where [Hash] the WHERE arguments to add to the query
  # @return [Hash] the return hash from the WQL query
  def run_wql(query, _namespace: 'root/virtualization/v2', **where)
    args = Fog::Hyperv.camelize(where).reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
      "#{k} = #{((v.is_a?(String) || v.to_s =~ /\s/) && v.inspect) || v}"
    end

    query = "#{query}#{" WHERE #{args.join ' AND '}" unless args.none?}"

    Fog::Logger.debug "WQL; in #{_namespace} >>> #{query}"
    data =
      if local?
        raise NotImplementedError, 'Not implemented for local connection'
        # run_cmd('Get-WmiObject', query:, namespace:, _return_fields: options.keys)
      else
        @connection.run_wql(query, "#{_namespace}/*")[:xml_fragment].first
      end
    Fog::Logger.debug "WQL; <<< #{data}"

    data
  end

  private

  def version
    @version ||= begin
      run_wql('SELECT Version FROM Win32_OperatingSystem', _namespace: 'root/cimv2')[:version]
    rescue StandardError
      run_cmd(
        <<~CMD,
          $VMMS = if ([environment]::Is64BitProcess) {
            "$($env:SystemRoot)\\System32\\vmms.exe"
          } else {
            "$($env:SystemRoot)\\Sysnative\\vmms.exe"
          }
          (Get-Item $VMMS).VersionInfo.ProductVersion"
        CMD
        _skip_json: true,
        _ps_version: 1
      ).stdout.strip
    end
  end

  def ps_version
    @ps_version ||= run_cmd('$PSVersionTable.PSVersion', _ps_version: 1)
  end

  def build_pscall(command, _by_id: nil, _return_fields: nil, _always_include: [], **options)
    _ps_version = options.delete(:_ps_version) { ps_version[:major] }
    _to_json = options.delete(:_to_json) { true }
    _json_depth = options.delete(:_json_depth) { 1 }

    pipeline = []
    pipeline << "Where-Object {$_.id -eq '#{_by_id}'}" if _by_id
    pipeline << "Select #{Fog::Hyperv.camelize([_return_fields].flatten).join ','}" if _return_fields
    pipeline << "ConvertTo-Json -Compress#{" -Depth #{_json_depth}" if _json_depth}" if _to_json

    invalid_opts = options.select { |k, _| k.to_s.start_with? '_' }
    Fog::Logger.debug "build_pscall given unexpected meta-arguments: #{invalid_opts.keys.join ', '}" if invalid_opts.any?

    options.reject! { |k, _| k.to_s.start_with?('_') }
    options.reject! do |k, v|
      !_always_include.include?(k) && (v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') || (v.is_a?(String) && v.empty?))
    end
    options = Fog::Hyperv.camelize(options.compact)

    command += ' @Args' unless command.include? '@Args'
    pipeline = [command] + pipeline
    Fog::Hyperv::Utils::Powershell.build_call(pipeline.join(' | '), options, _ps_version:)
  end

  def connection(host)
    existing = @connections.find do |c_host, c_connection|
      c_host.downcase.start_with?(host.downcase) ||
        URI(c_connection.instance_variable_get(:@connection_opts)[:endpoint]).host.downcase.start_with?(host.downcase)
    end

    if existing
      @connections[host] = existing unless @connections.key? host
      return existing.last
    end

    if %w[. localhost].include? host
      endpoint = @hyperv_endpoint
    else
      # TODO: Support non-standard endpoints for additional hosts
      unless host.include? '.'
        host = run_cmd("[System.Net.Dns]::GetHostByName(#{host.inspect})", _return_fields: :host_name, _ps_version: 1)[:host_name]
      end
      endpoint = "http://#{host}:5985/wsman"
    end

    existing = @connections.find do |_, c_connection|
      c_connection.instance_variable_get(:@connection_opts)[:endpoint] == endpoint
    end

    if existing
      @connections[host] = existing unless @connections.key? host
      return existing.last
    end

    connect(endpoint)
  end

  def connect(endpoint = nil)
    endpoint ||= @hyperv_endpoint
    fqdn = URI.parse(endpoint).host

    require 'winrm'

    opts = {
      endpoint: endpoint,
      transport: @hyperv_transport,
      user: @hyperv_username,
      password: @hyperv_password,
      realm: @hyperv_realm,
      no_ssl_peer_verification: true
    }

    Fog::Logger.debug "Creating WinRM connection with #{opts.merge password: '<REDACTED>'}"
    connection = WinRM::Connection.new opts
    connection.logger.level = :error
    @connections[fqdn] = connection

    # Add the local host's names to the connection
    begin
      hostname = run_cmd('$env:computerName', _target_computer: fqdn, _skip_json: true, _ps_version: 1).stdout.downcase.strip
      @connections[hostname] ||= connection
      fqdn = run_cmd(
        '[System.Net.Dns]::GetHostByName(($env:computerName)).Hostname',
        _target_computer: fqdn,
        _skip_json: true,
        _ps_version: 1
      ).stdout.downcase.strip
      @connections[fqdn] ||= connection
    end

    if endpoint == @hyperv_endpoint
      @connection = connection
      @connections['.'] = connection
      @connections['localhost'] = connection
      @local_hostname = hostname
    end

    connection
  end
end
# rubocop:enable Metrics/ModuleLength
