module Fog
  module Compute
    class Hyperv < Fog::Service
      recognizes :hyperv_endpoint, :hyperv_username, :hyperv_password,
                 :hyperv_transport

      model_path 'fog/hyperv/models/compute'
      model :server
      collection :servers
      # TODO: Design these properly
      # model :volume
      # collection :volumes

      request_path 'fog/hyperv/requests/compute'
      request :get_vm_host
      request :get_vm_host_cluster
      request :get_vm
      request :start_vm
      request :stop_vm
      request :get_vm_hard_disk_drive

      class Real
        def initialize(options = {})
          require 'psych'
          @hyperv_endpoint  = options[:hyperv_endpoint]
          @hyperv_username  = options[:hyperv_username]
          @hyperv_password  = options[:hyperv_password]
          @hyperv_transport = options[:hyperv_transport] || :negotiate

          connect
          verify
        end

        def local?
          @hyperv_server.nil?
        end

        private

        def run_shell(command, options = {})
          return_fields = options.delete :_return_fields
          return_fields = "| select #{Fog::Hyperv.camelize(return_fields).join ','}" if return_fields
          skip_json = options.delete :_skip_json
          skip_camelize = options.delete :_skip_camelize
          skip_uncamelize = options.delete :_skip_uncamelize

          # TODO: Generate an argument hash instead?
          # 
          # Would probably need to generate multi-line scripts in that case,
          # though that might help with VMId and clustering
          options = Fog::Hyperv.camelize(options) unless skip_camelize
          args = options.reject { |k, v| v.nil? }.map do |k, v|
            "-#{k} #{v}"
          end

          # TODO: Local machine communication
          out = @connection.shell(:powershell) do |shell|
            shell.run("#{command} #{args} #{return_fields} #{'| ConvertTo-Json -Compress' unless skip_json}")
          end

          # TODO: Map error codes in some manner
          raise Fog::Hyperv::ServiceError, out.stderr unless out.exitcode.zero?

          if skip_json
            out.stdout
          else
            json = Psych.load(out.stdout)
            Fog::Hyperv.uncamelize(json) unless skip_uncamelize
            json
          end
        end

        def connect
          return true if is_local?
          require 'winrm'

          @connection = WinRM::Connection.new(
            endpoint:  @hyperv_endpoint,
            user:      @hyperv_username,
            password:  @hyperv_password,
            transport: @hyperv_transport
          )
        end

        def verify
          @connection.shell(:powershell) do |shell|
            result = shell.run('get-vm')

            raise Fog::Hyperv::Errors::ServiceError, result.stderr unless result.exitcode.zero?
          end
        end
      end
    end
  end
end
