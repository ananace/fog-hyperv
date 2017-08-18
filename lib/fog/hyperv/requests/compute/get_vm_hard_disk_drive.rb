module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_hard_disk_drive(options = {})
          requires options, :vm_name
          run_shell('Get-VMHardDiskDrive', options)
        end
      end
    end
  end
end
