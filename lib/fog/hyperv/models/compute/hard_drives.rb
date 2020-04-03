# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class HardDrives < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::HardDrive

        get_method :get_vm_hard_disk_drive
      end
    end
  end
end
