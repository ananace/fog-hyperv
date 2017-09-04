module Fog
  module Compute
    class Hyperv
      class DvdDrive < Fog::Hyperv::Model
        identity :id

        attribute :computer_name
        # attribute :is_deleted
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :controller_location
        attribute :controller_number
        attribute :controller_type, type: :enum, values: %i[IDE SCSI]
        attribute :dvd_media_type, type: :enum, values: %i[None ISO Passthrough]
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?
        #

        def save
          requires :computer_name, :vm_name

          data = \
            if persisted?
              service.set_vm_dvd_drive(
                computer_name: old.computer_name,
                vm_name: old.vm_name,
                controller_number: old.controller_number,
                controller_location: old.controller_location,
                passthru: true,

                resource_pool_name: changed!(pool_name),
                path: changed?(path) && (path || '$null'),
                to_controller_number: changed!(controller_number),
                to_controller_location: changed!(controller_location),

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            else
              service.add_vm_dvd_drive(
                computer_name: computer_name,
                vm_name: vm_name,
                passthru: true,

                controller_number: controller_number,
                controller_location: controller_location,
                path: path,
                resource_pool_name: pool_name,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            end

          merge_attributes(data)
          @old = dup
          self
        end

        def destroy
          requires :computer_name, :vm_name, :controller_number, :controller_location

          service.remove_vm_dvd_drive(
            computer_name: computer_name,
            vm_name: vm_name,
            controller_number: controller_number,
            controller_location: controller_location
          )
        end

        def reload
          requires :computer_name, :vm_name

          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name,
            controller_location: controller_location,
            controller_number: controller_number,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end
      end
    end
  end
end
