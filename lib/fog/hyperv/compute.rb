# frozen_string_literal: true

require 'fog/core'

module Fog
  module Hyperv
    class Compute < Fog::Service
      requires :hyperv_username
      recognizes :hyperv_endpoint, :hyperv_host,
                 :hyperv_password,
                 :hyperv_transport, :hyperv_realm,
                 :hyperv_debug

      secrets :hyperv_password, :connection

      model_path 'fog/hyperv/compute/models'
      model :bios
      model :cluster
      collection :clusters
      model :com_port
      collection :com_ports
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
      model :network_adapter_vlan
      collection :network_adapters
      model :security
      model :server
      collection :servers
      model :switch
      collection :switches
      model :vhd
      collection :vhds

      request_path 'fog/hyperv/compute/requests'
      request :add_vm_dvd_drive
      request :add_vm_hard_disk_drive
      request :add_vm_network_adapter
      request :connect_vm_network_adapter
      request :disable_vm_tpm
      request :disconnect_vm_network_adapter
      request :enable_vm_tpm
      request :get_cluster
      request :get_cluster_node
      request :get_vhd
      request :get_vm
      request :get_vm_bios
      request :get_vm_com_port
      request :get_vm_dvd_drive
      request :get_vm_firmware
      request :get_vm_floppy_disk_drive
      request :get_vm_group
      request :get_vm_hard_disk_drive
      request :get_vm_host
      request :get_vm_host_cluster
      request :get_vm_host_sbt
      request :get_vm_key_protector
      request :get_vm_network_adapter
      request :get_vm_network_adapter_vlan
      request :get_vm_security
      request :get_vm_switch
      request :new_vhd
      request :new_vm
      request :new_vm_switch
      request :optimize_vhd
      request :remove_item
      request :remove_vm
      request :remove_vm_dvd_drive
      request :remove_vm_hard_disk_drive
      request :remove_vm_network_adapter
      request :remove_vm_switch
      request :rename_vm
      request :rename_vm_network_adapter
      request :rename_vm_switch
      request :resize_vhd
      request :restart_vm
      request :resume_vm
      request :save_vm
      request :set_vm
      request :set_vm_bios
      request :set_vm_com_port
      request :set_vm_dvd_drive
      request :set_vm_firmware
      request :set_vm_floppy_disk_drive
      request :set_vm_hard_disk_drive
      request :set_vm_key_protector
      request :set_vm_network_adapter
      request :set_vm_network_adapter_vlan
      request :set_vm_security
      request :set_vm_switch
      request :start_vm
      request :stop_vm
      request :suspend_vm

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
          raise(ArgumentError, "#{missing[0...-1].join(', ')}, or #{missing[-1]} is required for #{method}")
        end

        def requires_version(required_version)
          method = caller[0][/`.*'/][1..-2].split('_')
          method = "#{method[0].capitalize}-#{Fog::Hyperv.camelize(method[1..].join('_'))}"

          raise Fog::Hyperv::Errors::VersionError.new(required_version, version, method) \
            unless Gem::Version.new(version) >= Gem::Version.new(required_version)
        end
      end

      class Real < Shared
        include Fog::Hyperv::Utils::Winrm

        attr_reader :logger

        attr_accessor :bake_optmap, :bake_json

        def initialize(options = {}) # rubocop:disable Style/OptionHash, Lint/MissingSuper -- No super method
          require 'fog/json'
          require 'logging'

          # Transfer cmdlet parameters as JSON object
          @bake_json = true
          @bake_optmap = true

          @connections = {}
          @hyperv_endpoint = options[:hyperv_endpoint]
          @hyperv_endpoint ||= "http://#{options[:hyperv_host]}:5985/wsman" if options[:hyperv_host]
          @hyperv_username = options[:hyperv_username]
          @hyperv_password = options[:hyperv_password]
          @hyperv_realm = options[:hyperv_realm]
          @hyperv_transport = options[:hyperv_transport] || (@hyperv_realm ? :kerberos : :negotiate)

          # Hide NEGOTIATE logging from WinRM to reduce log spam when debugging
          Logging.logger['WinRM::HTTP::HttpNegotiate'].level = :error

          @logger = Logging.logger[Fog::Hyperv]
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
            run_cmd('Get-VMHost', _return_fields: :name) && true
          else
            run_wql('SELECT Name FROM Msvm_ComputerSystem WHERE Caption = "Hosting Computer System"')[:xml_fragment] && true
          end
        rescue StandardError => e
          logger.debug "Validation failed with #{e.class}; #{e.message}"
          false
        end

        def supports_multihop?
          [:kerberos].include? @hyperv_transport.to_s.downcase.to_sym
        end

        def supports_clusters?
          run_wql('SELECT Name FROM MSCluster_ResourceGroup', _namespace: 'root/mscluster/*')[:xml_fragment] && true
        rescue StandardError => e
          logger.debug "Cluster support checking failed with #{e.class}: #{e.message}"
          false
        end
      end

      class Mock < Shared
        def initialize(_options = {}) # rubocop:disable Lint/MissingSuper -- No super method
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
          Fog::Hyperv::Compute.requests.find { |_, k| k == method } || super
        end

        private

        def handle_mock_response(_method: nil, **args)
          if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('4.0')
            _method ||= caller[0][/'.*'/][1..-2].split('#').last
            _method ||= caller[1][/'.*'/][1..-2].split('#').last
          else
            _method ||= caller[0][/`.*'/][1..-2]
            _method ||= caller[1][/`.*'/][1..-2]
          end

          path = File.join File.dirname(__FILE__), 'compute', 'requests', 'mock_files', "#{_method}.json"
          raise Fog::Errors::MockNotImplemented, "No mocked data for #{path}" unless File.exist? path
          raise Fog::Errors::MockNotImplemented, 'Not implementing skipping of json' if args[:_skip_json]
          raise Fog::Errors::MockNotImplemented, 'Not implementing skipping of uncamelize' if args[:_skip_uncamelize]

          ret = Fog::JSON.decode(File.read(path))
          ret = Fog::Hyperv.uncamelize(ret)

          if args[:_return_fields]
            ret = ret.map do |obj|
              obj.slice(*args[:_return_fields])
            end
          end
          ret
        end
      end
    end
  end
end
