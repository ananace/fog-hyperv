module Fog
  module Compute
    module Hyperv
      class Real
        def get_vm(options = {})
          # TODO: Move this to a shared method
          return_fields = options.delete :_return_fields
          return_fields = "| select #{Fog::Hyperv.camelize(return_fields).join ','}" if return_fields
          args = Fog::Hyperv.camelize(options).map do |k, v|
            "-#{k} #{v}"
          end

          # TODO: Use a WinRM connection for local communication?
          out = @connection.shell(:powershell) do |shell|
            shell.run("Get-VM #{args} #{return_fields} | ConvertTo-Json -Compress")
          end

          # TODO: Map error codes in some manner
          raise Fog::Hyperv::ServiceError, out.stderr unless out.exitcode.zero?
          Fog::Hyperv.uncamelize(Psych.load(out.stdout))
        end
      end
    end
  end
end
