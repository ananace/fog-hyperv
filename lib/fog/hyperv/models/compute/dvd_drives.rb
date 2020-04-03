# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class DvdDrives < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::DvdDrive
        requires_vm

        get_method :get_vm_dvd_drive
      end
    end
  end
end
