module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_hard_disk_drive(options = {})
          run_shell('Set-VMHardDiskDrive', options)
        end
      end
    end
  end
end
