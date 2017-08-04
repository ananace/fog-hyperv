module Fog
  module Compute
    class Hyperv < Fog::Service
      recognizes :hyperv_endpoint, :hyperv_username, :hyperv_password,
                 :hyperv_transport

      model_path 'fog/hyperv/models/compute'
      model :server
      collection :servers

      request_path 'fog/hyperv/requests/compute'
      request :get_vm

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
