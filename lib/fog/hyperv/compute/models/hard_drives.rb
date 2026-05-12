# frozen_string_literal: true

class Fog::Hyperv::Compute
  class HardDrives < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::HardDrive

    get_method :get_vm_hard_disk_drive

    attribute :computer_name
    attribute :vm_id

    requires :vm_id

    def get(id, **filters)
      raise ArgumentError, 'Must provide a GUID' if id.nil? || id.empty?

      super(_by_id: id, **filters)
    end

    protected

    def search_attributes
      super.merge(
        _return_fields: model.attributes - %i[allow_unverified_paths vhd]
      )
    end
  end
end
