module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_hard_disk_drive(options = {})
          requires options, :vm_name
          run_shell('Set-VMHardDiskDrive', options)
        end
      end
    end
  end
end
