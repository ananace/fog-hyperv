module Fog
  module Compute
    class Hyperv < Fog::Service
      recognizes :hyperv_endpoint, :hyperv_host,
                 :hyperv_transport,
                 :hyperv_username, :hyperv_password,
                 :hyperv_debug

      model_path 'fog/hyperv/models/compute'
      model :server
      collection :servers
      # TODO: Design these properly
      # model :volume
      # collection :volumes
      model :interface
      collection :interfaces

      request_path 'fog/hyperv/requests/compute'
      request :get_vm_host
      request :get_vm_host_cluster
      request :get_vm
      request :start_vm
      request :stop_vm
      request :remove_vm
      request :get_vm_hard_disk_drive

      class Real
        def initialize(options = {})
          require 'json'
          require 'ostruct'
          require 'shellwords'

          @hyperv_endpoint  = options[:hyperv_endpoint]
          @hyperv_endpoint  = "http://#{options[:hyperv_host]}:5985/wsman" if @hyperv_endpoint.nil? && options[:hyperv_host]
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

        private

        def run_shell(command, options = {})
          return_fields = options.delete :_return_fields
          return_fields = "| select #{Fog::Hyperv.camelize([return_fields].flatten).join ','}" if return_fields
          skip_json = options.delete :_skip_json
          skip_camelize = options.delete :_skip_camelize
          skip_uncamelize = options.delete :_skip_uncamelize

          # TODO: Generate an argument hash instead?
          #
          # args = @{
          #   Name = etc
          # }
          # Get-VM *args
          options = Fog::Hyperv.camelize(options) unless skip_camelize
          args = options.reject { |k, v| v.nil? }.map do |k, v|
            "-#{k} #{Shellwords.escape v}"
          end

          commandline = "#{command} #{args.join ' ' unless args.empty?} #{return_fields} #{'| ConvertTo-Json -Compress' unless skip_json}"
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
          run_shell('Get-VM', _return_fields: 'Name') && true
        end
      end

      class Mock

      end
    end
  end
end
