module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_floppy_disk_drive(options = {})
          requires options, :vm_name
          run_shell('Get-VMFloppyDiskDrive', options)
        end
      end
    end
  end
end
