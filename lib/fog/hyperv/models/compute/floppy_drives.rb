module Fog
  module Compute
    class Hyperv
      class FloppyDrives < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::FloppyDrive
        requires_vm

        get_method :get_vm_floppy_disk_drive
      end
    end
  end
end
