module Fog
  module Compute
    class Hyperv
      class Real
        def add_vm_hard_disk_drive(options = {})
          run_shell('Add-VMHardDiskDrive', options)
        end
      end
    end
  end
end
