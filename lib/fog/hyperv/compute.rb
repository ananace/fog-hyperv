module Fog
  module Compute
    class Hyperv < Fog::Service
      STATUS_ENUM_VALUES = [
        :Unknown,              # 0
        :Other,                # 1
        :Ok,                   # 2
        :Degraded,             # 3
        :Stressed,             # 4
        :PredictiveFailure,    # 5
        :Error,                # 6
        :NonRecoverableError,  # 7
        :Starting,             # 8
        :Stopping,             # 9
        :Stopped,              # 10
        :InService,            # 11
        :NoContact,            # 12
        :LostCommunication,    # 13
        :Aborted,              # 14
        :Dormant,              # 15
        :SupportingEntity,     # 16
        :Completed,            # 17
        :PowerMode             # 18
        # :ProtocolVersion     # 32775
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
          if missing.length == 1
            raise(ArgumentError, "#{missing.first} is required for #{method}")
          elsif missing.any?
            raise(ArgumentError, "#{missing[0...-1].join(', ')}, and #{missing[-1]} are required for #{method}")
          end
        end

        def requires_one(opts, *args)
          missing = args - opts.keys
          return if missing.length < args.length

          method = caller[0][/`.*'/][1..-2]
          raise(ArgumentError, "#{missing[0...-1].join(', ')}, or #{missing[-1]} are required for #{method}")
        end

        def requires_version(required_version)
          method = caller[0][/`.*'/][1..-2].split('_')
          method = method[0].capitalize + "-" + Fog::Hyperv.camelize(method[1..-1].join('_'))

          raise Fog::Hyperv::Errors::VersionError.new(required_version, version, method) \
            unless Gem::Version.new(version) >= Gem::Version.new(required_version)
        end

      end

      class Real < Shared
        attr_reader :logger

        def initialize(options = {})
          # require 'ostruct'
          require 'fog/json'
          require 'logging'

          @connections = {}
          @hyperv_endpoint  = options[:hyperv_endpoint]
          @hyperv_endpoint  = "http://#{options[:hyperv_host]}:5985/wsman" if !@hyperv_endpoint && options[:hyperv_host]
          @hyperv_username  = options[:hyperv_username]
          @hyperv_password  = options[:hyperv_password]
          @hyperv_realm     = options[:hyperv_realm]
          @hyperv_transport = options[:hyperv_transport] || (@hyperv_realm ? :kerberos : :negotiate)

          Logging.logger['WinRM::HTTP::HttpNegotiate'].level = :error
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
            run_wql('SELECT Name FROM Msvm_ComputerSystem WHERE Caption = "Hosting Computer System"') && true
          end
        rescue => e
          logger.debug "Validation failed with #{e.class}; #{e.message}"
          false
        end

        def version
          @version ||= run_wql('SELECT Version FROM Win32_OperatingSystem', _namespace: 'root/cimv2/*')[:xml_fragment].first[:version] rescue \
            run_shell("$VMMS = if ([environment]::Is64BitProcess) { \"$($env:SystemRoot)\\System32\\vmms.exe\" } else { \"$($env:SystemRoot)\\Sysnative\\vmms.exe\" }\n(Get-Item $VMMS).VersionInfo.ProductVersion", _skip_json: true).stdout.strip
        end

        private

        def hash_to_optmap(options = {})
          args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
            "'#{k}'=#{Fog::Hyperv.shell_quoted(v, true)}"
          end
          "@{#{args.join ';'}}"
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
          computer = options.delete(:_target_computer) || '.'
          computers = [options.delete(:computer_name)].flatten.compact
          options = Fog::Hyperv.camelize(options) unless skip_camelize

          if computers.length > 1 || (computers.length == 1 && !['.','localhost'].include?(computers.first.downcase))
            puts "Executing multi-query for #{computers}"
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

          # commandline = "$Args = #{hash_to_optmap options}\n$Ret = #{command} @Args#{"\n$Ret #{return_fields} | ConvertTo-Json -Compress #{"-Depth #{json_depth}" if json_depth}" unless skip_json}"
          # puts " > #{commandline.split("\n").join "\n > "}" if @hyperv_debug
          args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') || (v.is_a?(String) && v.empty?) }.map do |k, v|
            "-#{k} #{Fog::Hyperv.shell_quoted v unless v.is_a?(TrueClass)}"
          end
          command_args = "#{command} #{args.join ' ' unless args.empty?}"
          commandline = "#{command_args} #{suffix} #{return_fields} #{"| ConvertTo-Json -Compress #{"-Depth #{json_depth}" if json_depth}" unless skip_json}"
          logger.debug "PS; >>> #{commandline}"

          out = nil # OpenStruct.new stdout: '',
          #                          stderr: '',
          #                          exitcode: -1

          if local?
            commanddata = [
              'powershell',
              '-NoLogo',
              '-NoProfile',
              '-NonInteractive',
              commandline
            ]
            begin
              out.stdout, out.stderr, out.exitcode = Open3.capture3(*commanddata)
              out.exitcode = out.exitcode.exitstatus
            rescue StandardError => ex
              out.stderr = ex.inspect
              out.exitcode = -1
            end
          else
            connection(computer).shell(:powershell) do |shell|
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
          endpoint = @hyperv_endpoint unless endpoint
          fqdn = URI.parse(endpoint).host

          require 'winrm'
          opts = {
            endpoint:  endpoint,
            transport: @hyperv_transport,
            user:      @hyperv_username,
            password:  @hyperv_password,
            realm:     @hyperv_realm
          }

          logger.debug "Creating WinRM connection with #{opts.merge password: '<REDACTED>'}"
          connection = WinRM::Connection.new opts
          connection.logger.level = :error
          @connections[fqdn] = connection
          
          if endpoint == @hyperv_endpoint
            @connection = connection
            @connections['.'] = connection
            @connections['localhost'] = connection
          end
        end

        def connection(host)
          c = @connections.find { |k,_v| k.downcase.start_with?(host.downcase) }
          return c[1] if c

          # TODO: Ensure host is a FQDN, add a connection for it
          raise NotImplementedError, "Can't dynamically add connections to additional computers"
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
