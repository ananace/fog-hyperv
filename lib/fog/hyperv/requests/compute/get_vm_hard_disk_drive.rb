module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_hard_disk_drive(options = {})
          # TODO: Would work better with getting the VM object by UUID instead
          name = options.delete(:vm_name) || options.delete(:name)
          run_shell('Get-VMHardDiskDrive', options.merge(VMName: name))
        end
      end
    end
  end
end
