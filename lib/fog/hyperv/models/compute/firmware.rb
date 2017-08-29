module Fog
  module Compute
    class Hyperv
      class Firmware < Fog::Hyperv::Model
        identity :vm_id

        attribute :boot_order
        attribute :computer_name
        attribute :console_mode, type: :enum, values: [ :Default, :COM1, :COM2, :None ]
        # attribute :is_deleted
        attribute :preferred_network_boot_protocol, type: :enum, values: [ :IPv4, :IPv6 ]
        attribute :secure_boot, type: :enum, values: [ :On, :Off ]
        attribute :vm_name

        def save
          requires :computer_name, :vm_name

          raise Fog::Hyperv::Errors::ServiceError, "Can't create Firmware instances" unless persisted?

          data = service.set_vm_firmware(
            computer_name: computer_name,
            vm_name: vm_name,
            passthru: true,

            enable_secure_boot: changed!(:secure_boot),
            preferred_network_boot_protocol: changed!(:preferred_network_boot_protocol),
            console_mode: changed!(:console_mode),

            _return_fields: self.class.attributes
          )

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          requires :computer_name, :vm_name

          data = service.get_vm_firmware(
            computer_name: computer_name,
            vm_name: vm_name,

            _return_fields: self.class.attributes
          )
          merge_attributes(data)
          self
        end
      end
    end
  end
end
