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
        attribute :controller_type, type: :enum, values: [ :IDE, :SCSI ]
        attribute :dvd_media_type, type: :enum, values: [ :None, :ISO, :Passthrough ]
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?
        #
        attr_accessor :to_controller_number, :to_controller_location

        def save
          requires :computer_name, :vm_name

          data = service.set_vm_dvd_drive(
            computer_name: computer_name,
            vm_name: vm_name,
            passthru: true,

            controller_number: controller_number,
            controller_location: controller_location,
            resource_pool_name: pool_name,
            path: path || '$null',
            to_controller_number: to_controller_number,
            to_controller_location: to_controller_location,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )
          merge_attributes(data)
          self
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
          self
        end
      end
    end
  end
end
