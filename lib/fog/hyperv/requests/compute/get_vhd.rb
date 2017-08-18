module Fog
  module Compute
    class Hyperv
      class Real
        def get_vhd(options = {})
          requires_one options, :vm_id, :path, :disk_number
          run_shell('Get-VHD', options)
        end
      end
    end
  end
end
