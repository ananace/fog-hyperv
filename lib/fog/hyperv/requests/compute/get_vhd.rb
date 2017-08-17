module Fog
  module Compute
    class Hyperv
      class Real
        def get_vhd(options = {})
          raise Fog::Hyperv::Errors::ServiceError, 'Requires vm_id, path, or disk_number' unless options[:vm_id] || options[:path] || options[:disk_number]
          run_shell('Get-VHD', options)
        end
      end
    end
  end
end
