module Fog
  module Compute
    class Hyperv
      class Firmware < Fog::Hyperv::Model
        identity :vm_id

        attribute :boot_order
        attribute :computer_name
        attribute :is_deleted
        attribute :preferred_network_boot_protocol
        attribute :secure_boot
        attribute :vm_name

        def save
          raise Fog::Hyperv::Errors::ServiceError, 'Not Implemented'
        end

        def reload
          data = service.get_firmware(
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
