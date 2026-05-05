# frozen_string_literal: true

class Fog::Hyperv::Compute
  class HardDrives < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::HardDrive

    get_method :get_vm_hard_disk_drive

    attribute :computer_name
    attribute :vm_id

    requires :vm_id

    def get(id, **filters)
      super(_by_id: id, **filters)
    end
  end
end
