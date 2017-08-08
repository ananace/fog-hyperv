module Fog
  module Compute
    class Hyperv
      class HardDrive < Fog::Model
        identity :id

        attribute :computer_name
        attribute :disk
        attribute :is_deleted
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :controller_location
        attribute :controller_number
        attribute :controller_type
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?

        def vhd
          @vhd ||= Fog::Compute::Hyperv::VHD.new(service.get_vhd(computer_name: computer_name, path: path).merge(service: service))
        end

        def reload
          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name,
            controller_location: controller_location,
            controller_number: controller_number,
            controller_type: controller_type
          )
          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
