# frozen_string_literal: true

class Fog::Hyperv::Compute
  class FloppyDrives < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::FloppyDrive

    get_method :get_vm_floppy_disk_drive

    attribute :computer_name
    attribute :vm_id

    requires :vm_id

    def get(id, **filters)
      super(_by_id: id, **filters)
    end
  end
end
