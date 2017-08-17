module Fog
  module Compute
    class Hyperv
      class Real
        def get_vhd(options = {})
          raise Fog::Hyperv::ServiceError, 'Requires path or disk_number' unless options[:path] || options[:disk_number]
          run_shell('Get-VHD', options)
        end
      end
    end
  end
end
