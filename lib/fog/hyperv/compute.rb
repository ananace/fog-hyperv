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
      request :connect_vm_network_adapter
      request :disconnect_vm_network_adapter
      request :get_vhd
      request :get_vm
      request :get_vm_bios
      request :get_vm_dvd_drive
      request :get_vm_firmware
      request :get_vm_hard_disk_drive
      request :get_vm_host
      request :get_vm_host_cluster
      request :get_vm_network_adapter
      request :get_vm_switch
      request :new_vm
      request :new_vm_switch
      request :remove_vm
      request :restart_vm
      request :set_vm
      request :set_vm_bios
      request :set_vm_dvd_drive
      request :set_vm_firmware
      request :set_vm_switch
      request :start_vm
      request :stop_vm

      class Real
        def initialize(options = {})
          require 'json'
          require 'ostruct'

          @hyperv_endpoint  = options[:hyperv_endpoint]
          @hyperv_endpoint  = "http://#{options[:hyperv_host]}:5985/wsman" if !@hyperv_endpoint && options[:hyperv_host]
          @hyperv_username  = options[:hyperv_username]
          @hyperv_password  = options[:hyperv_password]
          @hyperv_transport = options[:hyperv_transport] || :negotiate
          @hyperv_debug     = options[:hyperv_debug]

          connect
          verify
        end

        def local?
          @hyperv_endpoint.nil?
        end

        def interfaces
          network_adapters
        end

        private

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

          commandline = "#{command}#{suffix} #{args.join ' ' unless args.empty?} #{return_fields} #{"| ConvertTo-Json -Compress #{"-Depth #{json_depth}" if json_depth}" unless skip_json}"
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
          raise Fog::Hyperv::Errors::ServiceError, out.stderr unless out.exitcode.zero?

          puts " < [stdout: #{out.stdout.inspect}, stderr: #{out.stderr.inspect}]" if @hyperv_debug

          if skip_json
            out.stdout
          else
            json = JSON.parse(out.stdout, symbolize_names: true)
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
        end

        def verify
          run_shell('Get-VMHost', _return_fields: :name) && true
        end
      end

      class Mock

      end
    end
  end
end
