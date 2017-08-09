module Fog
  module Compute
    class Hyperv
      class DvdDrives < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::DvdDrive

        get_method :get_vm_dvd_drive
      end
    end
  end
end
