module Fog
  module Compute
    class Hyperv < Fog::Service
      recognizes :hyperv_endpoint, :hyperv_host,
                 :hyperv_transport,
                 :hyperv_username, :hyperv_password,
                 :hyperv_debug

      model_path 'fog/hyperv/models/compute'
      model :bios
      model :dvd_drive
      collection :dvd_drives
      model :firmware
      model :floppy_drive
      collection :floppy_drives
      model :hard_drive
      collection :hard_drives
      model :network_adapter
      collection :network_adapters
      model :server
      collection :servers
      model :switch
      collection :switches
      model :vhd

      request_path 'fog/hyperv/requests/compute'
      request :add_vm_hard_disk_drive
      request :connect_vm_network_adapter
      request :disconnect_vm_network_adapter
      request :get_vhd
      request :get_vm
      request :get_vm_bios
      request :get_vm_dvd_drive
      request :get_vm_firmware
      request :get_vm_floppy_disk_drive
      request :get_vm_hard_disk_drive
      request :get_vm_host
      request :get_vm_host_cluster
      request :get_vm_network_adapter
      request :get_vm_switch
      request :new_vm
      request :new_vm_switch
      request :remove_item
      request :remove_vm
      request :remove_vm_hard_disk_drive
      request :restart_vm
      request :set_vm
      request :set_vm_bios
      request :set_vm_dvd_drive
      request :set_vm_hard_disk_drive
      request :set_vm_firmware
      request :set_vm_switch
      request :start_vm
      request :stop_vm

      class Real
        def initialize(options = {})
          require 'ostruct'
          require 'fog/json'

          @hyperv_endpoint  = options[:hyperv_endpoint]
          @hyperv_endpoint  = "http://#{options[:hyperv_host]}:5985/wsman" if !@hyperv_endpoint && options[:hyperv_host]
          @hyperv_username  = options[:hyperv_username]
          @hyperv_password  = options[:hyperv_password]
          @hyperv_transport = options[:hyperv_transport] || :negotiate
          @hyperv_debug     = options[:hyperv_debug]

          connect
        end

        def local?
          @hyperv_endpoint.nil?
        end

        def valid?
          if local?
            run_shell('Get-VMHost', _return_fields: :name) && true
          else
            run_wql('SELECT Name FROM Msvm_ComputerSystem WHERE Caption = "Hosting Computer System"') && true
          end
        rescue Fog::Hyperv::Errors::ServiceError
          false
        end

        private

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
              puts "< #{namespace} => #{query}"
              @connection.run_wql(query, namespace)
            end

          puts "> #{data}"
          data
        end

        def run_shell(command, options = {})
          return_fields = options.delete :_return_fields
          return_fields = "| select #{Fog::Hyperv.camelize([return_fields].flatten).join ','}" if return_fields
          json_depth = options.delete :_json_depth
          suffix = options.delete :_suffix
          skip_json = options.delete :_skip_json
          skip_camelize = options.delete :_skip_camelize
          skip_uncamelize = options.delete :_skip_uncamelize

          # TODO: Generate an argument hash instead?
          # TODO: Needs some testing for multi-line PS execution both local and remote
          #
          # args = @{
          #   Name = etc
          # }
          # Get-VM *args
          options = Fog::Hyperv.camelize(options) unless skip_camelize
          args = options.reject { |k, v| v.nil? || v.is_a?(FalseClass) || k.to_s.start_with?('_') }.map do |k, v|
            "-#{k} #{Fog::Hyperv.shell_quoted v unless v.is_a? TrueClass}"
          end

          command_args = "#{command}#{suffix} #{args.join ' ' unless args.empty?}"
          commandline = "#{command_args} #{return_fields} #{"| ConvertTo-Json -Compress #{"-Depth #{json_depth}" if json_depth}" unless skip_json}"
          puts " > #{commandline}" if @hyperv_debug

          out = OpenStruct.new stdout: '',
                               stderr: '',
                               exitcode: -1

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
            @connection.shell(:powershell) do |shell|
              out = shell.run(commandline)
            end
          end

          # TODO: Map error codes in some manner?
          raise Fog::Hyperv::Errors::ServiceError, "Failed to execute #{commandline}" unless out
          raise Fog::Hyperv::Errors::PSError.new(out, "When executing #{command_args}") unless out.exitcode.zero?

          puts " < [stdout: #{out.stdout.inspect}, stderr: #{out.stderr.inspect}]" if @hyperv_debug

          if skip_json
            out
          else
            return nil if out.stdout.empty?
            json = Fog::JSON.decode(out.stdout)
            json = Fog::Hyperv.uncamelize(json) unless skip_uncamelize
            json
          end
        end

        def connect
          return require 'open3' if local?

          require 'winrm'
          @connection = WinRM::Connection.new(
            endpoint:  @hyperv_endpoint,
            user:      @hyperv_username,
            password:  @hyperv_password,
            transport: @hyperv_transport
          )
          Logging.logger['WinRM::HTTP::HttpNegotiate'].level = :error
          @connection.logger.level = :error
        end
      end

      class Mock

      end
    end
  end
end
