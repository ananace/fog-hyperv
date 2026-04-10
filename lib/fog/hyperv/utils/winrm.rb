# frozen_string_literal: true

module Fog
  module Hyperv
    module Utils
      module Winrm
        LocalExecOutput = Struct.new(:stdout, :stderr, :exitcode)

        private

        def version
          @version ||= begin
            run_wql('SELECT Version FROM Win32_OperatingSystem', _namespace: 'root/cimv2/*')[:xml_fragment].first[:version]
          rescue StandardError
            run_shell(
              <<~CMD, _skip_json: true
                $VMMS = if ([environment]::Is64BitProcess) {
                  "$($env:SystemRoot)\\System32\\vmms.exe"
                } else {
                  "$($env:SystemRoot)\\Sysnative\\vmms.exe"
                }
                (Get-Item $VMMS).VersionInfo.ProductVersion"
              CMD
            ).stdout.strip
          end
        end

        def ps_version
          @ps_version ||= run_shell('$PSVersionTable.PSVersion', _bake_optmap: false, _bake_json: false)
        end

        # TODO
        # def run_shell_with_vm(command, vm_options, options = {})
        #   $VM = Get-VM @vm_options
        #   $Result = <command> @options
        #   $Result | select <return_fields> | ConvertTo-Json
        # end

        def hash_to_optmap(optmap_name: 'FogArgs', _bake_json: false, **options)
          if _bake_json
            if ps_version[:major] >= 6
              "$#{optmap_name} = ConvertFrom-Json -AsHashtable '#{Fog::JSON.encode options.compact}'"
            else
              <<~CMD
                $FogJsonObject = '#{Fog::JSON.encode options.compact}'
                $FogJsonParameters = ConvertFrom-Json -InputObject $FogJsonObject
                $#{optmap_name} = @{}
                $FogJsonParameters.psobject.properties | Foreach { $#{optmap_name}[$_.Name] = $_.Value }
              CMD
            end
          else
            args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
              "'#{k}'=#{Fog::Hyperv.shell_quoted(v, always: true)}"
            end

            "$Args = @{#{args.join ';'}}"
          end
        end

        def run_wql(query, _namespace: 'root/virtualization/v2/*', **options)
          skip_camelize = options.delete :_skip_camelize

          options = Fog::Hyperv.camelize(options) unless skip_camelize
          args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
            "#{k} = #{((v.is_a?(String) || v.to_s =~ /\s/) && v.inspect) || v}"
          end

          query = "#{query}#{" WHERE #{args.join ' AND '}" unless args.none?}"
          data =
            if local?
              raise NotImplementedError, 'Local WQL queries are not implemented'
            else
              Fog::Logger.debug "WQL; #{namespace} >>> #{query}"
              @connection.run_wql(query, namespace)
            end

          Fog::Logger.debug "WQL; <<< #{data}"
          data
        end

        def run_shell(command, _always_include: [], _target_computer: '.', **options)
          orig_opts = options.dup
          return_fields = options.delete :_return_fields
          return_fields = "| select #{Fog::Hyperv.camelize([return_fields].flatten).join ','}" if return_fields
          suffix = options.delete :_suffix
          json_depth = options.delete :_json_depth
          skip_json = options.delete :_skip_json
          skip_args = options.delete :_skip_args
          skip_camelize = options.delete :_skip_camelize
          skip_uncamelize = options.delete :_skip_uncamelize
          bake_optmap = options.delete(:_bake_optmap) { |_| @bake_optmap }
          bake_json = options.delete(:_bake_json) { |_| @bake_json }
          computers = [options.delete(:computer_name)].flatten.compact
          options.delete_if { |o| o.to_s.start_with?('_') }

          _always_include = Fog::Hyperv.camelize(_always_include) unless skip_camelize
          options = Fog::Hyperv.camelize(options) unless skip_camelize

          if supports_multihop?
            options[:computer_name] = computers
            _target_computer = '.'
          elsif computers.length > 1 || (computers.length == 1 && !['.', 'localhost', @local_hostname].include?(computers.first.downcase))
            Fog::Logger.debug "Executing multi-query for #{computers}"
            ret = []
            computers.each do |c|
              out = run_shell(command, _target_computer: c, **orig_opts.merge(computer_name: nil))
              if out.is_a? Array
                ret += out
              else
                ret << out
              end
            end
            return ret.first if ret.length == 1

            return ret
          end

          if !skip_args && options.any?
            command = "#{command} @Args" unless command.include? '@Args'
            args = options.reject do |k, v|
              !_always_include.include?(k) && (v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') || (v.is_a?(String) && v.empty?))
            end
            if bake_optmap
              prefix = "#{hash_to_optmap(_bake_json: bake_json, **args)}\n"
              command = command.gsub('@Args', '@FogArgs')
            else
              args = args.map do |k, v|
                "-#{k} #{Fog::Hyperv.shell_quoted v if !v.is_a?(TrueClass) || _always_include.include?(k)}"
              end
              command = command.gsub('@Args', args.join(' '))
            end
          elsif !skip_args
            command = command.gsub('@Args', '')
          end
          compress_json = "| ConvertTo-Json -Compress #{"-Depth #{json_depth}" if json_depth}" unless skip_json
          commandline = [prefix, command, suffix, return_fields, compress_json].compact.join ' '
          Fog::Logger.debug "PS; >>> #{commandline}"

          out = nil
          if local?
            commanddata = [
              'powershell',
              '-NoLogo',
              '-NoProfile',
              '-NonInteractive',
              commandline
            ]
            begin
              out = LocalExecOutput.new('', '', -1)
              out.stdout, out.stderr, out.exitcode = Open3.capture3(*commanddata)
              out.exitcode = out.exitcode.exitstatus
            rescue StandardError => e
              out.stderr = e.inspect
              out.exitcode = -1
            end
          else
            connection(_target_computer).shell(:powershell) do |shell|
              # TODO: Reuse shell?
              # XXX   Multiple commands in one invokation?
              out = shell.run(commandline)
            end
          end

          # TODO: Map error codes in some manner?
          raise Fog::Hyperv::Errors::ServiceError, "Failed to execute #{commandline}" unless out
          raise Fog::Hyperv::Errors::PSError.new(out, "When executing #{command}") unless out.exitcode.zero?

          Fog::Logger.debug "PS; <<< OUT=[#{out.stdout.inspect}] ERR=[#{out.stderr.inspect}] EXIT=[#{out.exitcode}]"

          if skip_json
            out
          else
            return nil if out.stdout.empty?

            json = Fog::JSON.decode(out.stdout)
            json = Fog::Hyperv.uncamelize(json) unless skip_uncamelize
            json
          end
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
            hostname = run_shell('$env:computerName', _skip_args: true, _skip_uncamelize: true, _target_computer: fqdn).downcase
            @connections[hostname] ||= connection
            fqdn = run_shell('[System.Net.Dns]::GetHostByName(($env:computerName)).Hostname', _skip_args: true,
                                                                                              _skip_uncamelize: true,
                                                                                              _target_computer: fqdn).downcase
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
              host = run_shell("[System.Net.Dns]::GetHostByName(#{host.inspect})", _return_fields: :host_name)[:host_name]
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
      end
    end
  end
end
