# frozen_string_literal: true

# Temporarily disable debug output, will be removed before release
require 'winrm'
class WinRM::HTTP::HttpTransport
  def log_soap_message(_); end
end

module Fog
  module Compute
    class Hyperv < Fog::Service
      STATUS_ENUM_VALUES = [
        Unknown: 0,
        Other: 1,
        Ok: 2,
        Degraded: 3,
        Stressed: 4,
        PredictiveFailure: 5,
        Error: 6,
        NonRecoverableError: 7,
        Starting: 8,
        Stopping: 9,
        Stopped: 0,
        InService: 1,
        NoContact: 2,
        LostCommunication: 3,
        Aborted: 4,
        Dormant: 5,
        SupportingEntity: 6,
        Completed: 7,
        PowerMode: 8,
        ProtocolVersion: 32_775
      ].freeze

      requires :hyperv_username
      recognizes :hyperv_endpoint, :hyperv_host,
                 :hyperv_password,
                 :hyperv_transport, :hyperv_realm,
                 :hyperv_debug

      secrets :hyperv_password, :connection

      model_path 'fog/hyperv/models/compute'
      model :bios
      model :cluster
      collection :clusters
      model :com_port
      model :dvd_drive
      collection :dvd_drives
      model :firmware
      model :floppy_drive
      collection :floppy_drives
      model :hard_drive
      collection :hard_drives
      model :host
      collection :hosts
      model :network_adapter
      collection :network_adapters
      model :server
      collection :servers
      model :switch
      collection :switches
      model :vhd
      collection :vhds

      request_path 'fog/hyperv/requests/compute'
      request :add_vm_dvd_drive
      request :add_vm_hard_disk_drive
      request :add_vm_network_adapter
      request :connect_vm_network_adapter
      request :disconnect_vm_network_adapter
      request :get_cluster
      request :get_cluster_node
      request :get_vhd
      request :get_vm
      request :get_vm_bios
      request :get_vm_dvd_drive
      request :get_vm_firmware
      request :get_vm_floppy_disk_drive
      request :get_vm_group
      request :get_vm_hard_disk_drive
      request :get_vm_host
      request :get_vm_host_cluster
      request :get_vm_network_adapter
      request :get_vm_switch
      request :new_vhd
      request :new_vm
      request :new_vm_switch
      request :remove_item
      request :remove_vm
      request :remove_vm_dvd_drive
      request :remove_vm_hard_disk_drive
      request :remove_vm_network_adapter
      request :restart_vm
      request :set_vm
      request :set_vm_bios
      request :set_vm_dvd_drive
      request :set_vm_hard_disk_drive
      request :set_vm_firmware
      request :set_vm_network_adapter
      request :set_vm_network_adapter_vlan
      request :set_vm_switch
      request :start_vm
      request :stop_vm

      class Shared
        def version
          '0.0'
        end

        protected

        def requires(opts, *args)
          missing = args - opts.keys
          return if missing.none?

          method = caller[0][/`.*'/][1..-2]
          raise(ArgumentError, "#{missing.first} is required for #{method}") if missing.length == 1
          raise(ArgumentError, "#{missing[0...-1].join(', ')}, and #{missing[-1]} are required for #{method}") if missing.any?
        end

        def requires_one(opts, *args)
          missing = args - opts.keys
          return if missing.length < args.length

          method = caller[0][/`.*'/][1..-2]
          raise(ArgumentError, "#{missing[0...-1].join(', ')}, or #{missing[-1]} are required for #{method}")
        end

        def requires_version(required_version)
          method = caller[0][/`.*'/][1..-2].split('_')
          method = method[0].capitalize + '-' + Fog::Hyperv.camelize(method[1..-1].join('_'))

          raise Fog::Hyperv::Errors::VersionError.new(required_version, version, method) \
            unless Gem::Version.new(version) >= Gem::Version.new(required_version)
        end

      end

      class Real < Shared
        attr_reader :logger

        attr_accessor :bake_optmap, :bake_json

        def initialize(options = {})
          # require 'ostruct'
          require 'fog/json'
          require 'logging'

          @connections = {}
          @hyperv_endpoint = options[:hyperv_endpoint]
          @hyperv_endpoint ||= "http://#{options[:hyperv_host]}:5985/wsman" if options[:hyperv_host]
          @hyperv_username = options[:hyperv_username]
          @hyperv_password = options[:hyperv_password]
          @hyperv_realm = options[:hyperv_realm]
          @hyperv_transport = options[:hyperv_transport] || (@hyperv_realm ? :kerberos : :negotiate)

          # Logging.logger['WinRM::HTTP::HttpNegotiate'].level = :error
          @logger = Logging.logger['hyper-v']
          if options[:hyperv_debug]
            logger.level = :debug
            logger.add_appenders Logging.appenders.stdout
          end

          connect
        end

        def local?
          false # @hyperv_endpoint.nil?
        end

        def valid?
          if local?
            run_shell('Get-VMHost', _return_fields: :name) && true
          else
            run_wql('SELECT Name FROM Msvm_ComputerSystem WHERE Caption = "Hosting Computer System"')[:xml_fragment] && true
          end
        rescue => e
          logger.debug "Validation failed with #{e.class}; #{e.message}"
          false
        end

        def supports_multihop?
          [:kerberos].include? @hyperv_transport.to_s.downcase.to_sym
        end

        def supports_clusters?
          run_wql('SELECT Name FROM MSCluster_ResourceGroup', _namespace: 'root/mscluster/*')[:xml_fragment] && true
        rescue => e
          logger.debug "Cluster support checking failed with #{e.class}: #{e.message}"
          false
        end

        def version
          @version ||= begin
            run_wql('SELECT Version FROM Win32_OperatingSystem', _namespace: 'root/cimv2/*')[:xml_fragment].first[:version]
          rescue
            run_shell("$VMMS = if ([environment]::Is64BitProcess) { \"$($env:SystemRoot)\\System32\\vmms.exe\" } else { \"$($env:SystemRoot)\\Sysnative\\vmms.exe\" }\n(Get-Item $VMMS).VersionInfo.ProductVersion", _skip_json: true).stdout.strip
          end
        end

        def ps_version
          @ps_version ||= run_shell('$PSVersionTable.PSVersion', _bake_optmap: false, _bake_json: false)
        end

        private

        def hash_to_optmap(options = {})
          bake_json = options.delete :_bake_json
          if bake_json
            if ps_version[:major] >= 6
              "$Args = ConvertFrom-Json -AsHashtable '#{Fog::JSON.encode options.reject(&:nil?)}'"
            else
              <<~CMD
                $JsonObject = '#{Fog::JSON.encode options.reject(&:nil?)}'
                $JsonParameters = ConvertFrom-Json -InputObject $JsonObject
                $Args = $JsonParameters.psobject.properties | foreach -begin {$h=@{}} -process {$h."$($_.Name)" = $_.Value} -end {$h}
              CMD
            end
          else
            args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
              "'#{k}'=#{Fog::Hyperv.shell_quoted(v, true)}"
            end

            "$Args = @{#{args.join ';'}}"
          end
        end

        def run_shell_with_vm(command, vm_options, options = {})
          # $VM = Get-VM @vm_options
          # $Result = <command> @options
          # $Result | select <return_fields> | ConvertTo-Json
        end

        def run_wql(query, options = {})
          skip_camelize = options.delete :_skip_camelize
          namespace = options.delete(:_namespace) || 'root/virtualization/v2/*'

          options = Fog::Hyperv.camelize(options) unless skip_camelize
          args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
            "#{k} = #{(v.is_a?(String) || v.to_s =~ /\s/) && v.inspect || v}"
          end

          query = "#{query}#{" WHERE #{args.join ' AND '}" unless args.none?}"
          data = \
            if local?
              # TODO
            else
              logger.debug "WQL; #{namespace} >>> #{query}"
              @connection.run_wql(query, namespace)
            end

          logger.debug "WQL; <<< #{data}"
          data
        end

        def run_shell(command, options = {})
          orig_opts = options.dup
          return_fields = options.delete :_return_fields
          return_fields = "| select #{Fog::Hyperv.camelize([return_fields].flatten).join ','}" if return_fields
          suffix = options.delete :_suffix
          json_depth = options.delete :_json_depth
          skip_json = options.delete :_skip_json
          skip_camelize = options.delete :_skip_camelize
          skip_uncamelize = options.delete :_skip_uncamelize
          always_include = options.delete(:_always_include) {|_| []}
          bake_optmap = options.delete(:_bake_optmap) {|_| @bake_optmap }
          bake_json = options.delete(:_bake_json) {|_| @bake_json }
          computer = options.delete(:_target_computer) || '.'
          computers = [options.delete(:computer_name)].flatten.compact
          options.delete_if { |o| o.to_s.start_with?('_') }

          always_include = Fog::Hyperv.camelize(always_include) unless skip_camelize
          options = Fog::Hyperv.camelize(options) unless skip_camelize

          if supports_multihop?
            options[:computer_name] = computers
            computer = '.'
          elsif computers.length > 1 || (computers.length == 1 && !['.', 'localhost', @local_hostname].include?(computers.first.downcase))
            logger.debug "Executing multi-query for #{computers}"
            ret = []
            computers.each do |c|
              out = run_shell(command, orig_opts.merge(computer_name: nil, _target_computer: c))
              if out.is_a? Array
                ret += out
              else
                ret << out
              end
            end
            return ret.first if ret.length == 1
            return ret
          end

          args = options.reject { |k, v| !always_include.include?(k) && (v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') || (v.is_a?(String) && v.empty?)) }.map do |k, v|
            "-#{k} #{Fog::Hyperv.shell_quoted v if !v.is_a?(TrueClass) || always_include.include?(k)}"
          end

          if bake_optmap
            command_args = "#{hash_to_optmap options.merge(_bake_json: bake_json)}\n\n#{command} @Args"
          else
            command_args = "#{command} #{args.join ' ' unless args.empty?}"
          end
          commandline = "#{command_args} #{suffix} #{return_fields} #{"| ConvertTo-Json -Compress #{"-Depth #{json_depth}" if json_depth}" unless skip_json}"
          logger.debug "PS; >>> #{commandline}"

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
              out = OpenStruct.new stdout: '',
                                   stderr: '',
                                   exitcode: -1
              out.stdout, out.stderr, out.exitcode = Open3.capture3(*commanddata)
              out.exitcode = out.exitcode.exitstatus
            rescue StandardError => ex
              out.stderr = ex.inspect
              out.exitcode = -1
            end
          else
            connection(computer).shell(:powershell) do |shell|
              # TODO: Reuse shell?
              # XXX   Multiple commands in one invokation?
              out = shell.run(commandline)
            end
          end

          # TODO: Map error codes in some manner?
          raise Fog::Hyperv::Errors::ServiceError, "Failed to execute #{commandline}" unless out
          raise Fog::Hyperv::Errors::PSError.new(out, "When executing #{command_args}") unless out.exitcode.zero?

          logger.debug "PS; <<< OUT=[#{out.stdout.inspect}] ERR=[#{out.stderr.inspect}] EXIT=[#{out.exitcode}]"

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

          logger.debug "Creating WinRM connection with #{opts.merge password: '<REDACTED>'}"
          connection = WinRM::Connection.new opts
          connection.logger.level = :error
          @connections[fqdn] = connection

          # Add the local host's names to the connection
          begin
            hostname = run_shell('$env:computerName', _skip_uncamelize: true, _target_computer: fqdn).downcase
            @connections[hostname] ||= connection
            fqdn = run_shell('[System.Net.Dns]::GetHostByName(($env:computerName)).Hostname', _skip_uncamelize: true, _target_computer: fqdn).downcase
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

      class Mock < Shared
        def initialize(_options = {})
          require 'fog/json'
        end

        def method_missing(method, *args)
          if requests.find { |_, k| k == method }
            handle_mock_response((args.first || {}).merge(_method: method))
          else
            super
          end
        end

        def respond_to_missing?(method, include_private = false)
          requests.find { |_, k| k == method } || super
        end

        def self.method_defined?(method)
          Fog::Compute::Hyperv.requests.find { |_, k| k == method } || super
        end

        private

        def handle_mock_response(args = {})
          method =   args.delete :_method
          method ||= caller[0][/`.*'/][1..-2]
          method ||= caller[1][/`.*'/][1..-2]

          path = File.join File.dirname(__FILE__), 'requests', 'compute', 'mock_files', "#{method}.json"
          Fog::Mock.not_implemented unless File.exist? path
          raise Fog::Errors::MockNotImplemented, 'Not implementing skipping of json' if args[:_skip_json]
          raise Fog::Errors::MockNotImplemented, 'Not implementing skipping of uncamelize' if args[:_skip_uncamelize]

          ret = Fog::JSON.decode(open(path).read)
          ret = Fog::Hyperv.uncamelize(ret)

          ret = ret.map do |obj|
            obj.select { |k, _| args[:_return_fields].include? k }
          end if args[:_return_fields]
          ret
        end
      end
    end
  end
end
