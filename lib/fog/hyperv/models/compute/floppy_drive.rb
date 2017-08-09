module Fog
  module Compute
    class Hyperv
      class FloppyDrive < Fog::Model
        identity :id

        attribute :computer_name
        attribute :disk
        attribute :is_deleted
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?
        #

        def save
          requires :computer_name, :vm_name

          data = service.set_vm_floppy_disk_drive(
            computer_name: computer_name,
            vm_name: vm_name,
            passthru: true,

            resource_pool_name: pool_name,
            path: path,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )

          merge_attributes(data)
          self
        end

        def reload
          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name
          )
          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
