# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class Firmware < Fog::Hyperv::Model
        # @!attribute [r] computer_name
        #   @return [String] The name of the computer running the VM that this UEFI configuration is attached to
        attribute :computer_name
        # @!attribute [r] vm_id
        #   @return [String] The GUID of the VM this UEFI configuration is attached to
        identity :vm_id
        # @!attribute [r] vm_name
        #   @return [String] The name of the VM this UEFI configuration is attached to
        attribute :vm_name

        # @!attribute [r] boot_order
        #   @return [Array<String>] The boot order of the VM
        attribute :boot_order
        # @!attribute console_mode
        #   @return [:Default, :COM1, :COM2, :None] Where the console output should be directed
        attribute :console_mode, type: :enum, values: %i[Default COM1 COM2 None]
        # attribute :is_deleted
        # @!attribute preferred_network_boot_protocol
        #   @return [:IPv4, :IPv6] The preffered IP protocol for PXE
        attribute :preferred_network_boot_protocol, type: :enum, values: %i[IPv4 IPv6]
        # @!attribute secure_boot
        #   @return [:On, :Off] Should secure boot be enabled
        #   @see ON_OFF_STATE_ENUM_VALUES
        attribute :secure_boot, type: :enum, values: ON_OFF_STATE_ENUM_VALUES
        # @!attribute secure_boot_template
        #   @return [String] The template to use for the secure boot configuration
        #   @see Host#secure_boot_templates
        attribute :secure_boot_template
        # @!attribute pause_after_boot_failure
        #   @return [:On, :Off] Should the VM pause after failing boot
        #   @see ON_OFF_STATE_ENUM_VALUES
        attribute :pause_after_boot_failure, type: :enum, values: ON_OFF_STATE_ENUM_VALUES

        def save
          requires :computer_name, :vm_name

          raise Fog::Hyperv::Errors::ServiceError, "Can't create Firmware instances" unless persisted?

          data = service.set_vm_firmware(
            computer_name: computer_name,
            vm_name: vm_name,
            passthru: true,

            enable_secure_boot: changed!(:secure_boot),
            secure_boot_template: changed!(:secure_boot_template),
            preferred_network_boot_protocol: changed!(:preferred_network_boot_protocol),
            console_mode: changed!(:console_mode),
            pause_after_boot_failure: changed!(:pause_after_boot_failure),

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
          @old = data
          self
        end
      end
    end
  end
end
