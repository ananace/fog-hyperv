# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class FloppyDrive < Fog::Hyperv::Model
        identity :id

        attribute :computer_name
        attribute :disk
        # attribute :is_deleted
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?
        #

        def save
          raise Fog::Hyperv::Errors::ServiceError, "Can't create new floppy drives" unless persisted?

          requires :computer_name, :vm_name

          data = \
            service.set_vm_floppy_disk_drive(
              computer_name: old.computer_name,
              vm_name: old.vm_name,
              passthru: true,

              resource_pool_name: changed!(:pool_name),
              path: changed?(:path) && (path || '$null'),

              _return_fields: self.class.attributes,
              _json_depth: 1
            )

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end
      end
    end
  end
end
