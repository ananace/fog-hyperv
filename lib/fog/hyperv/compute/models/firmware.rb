# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Firmware < Fog::Hyperv::Model
    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this UEFI configuration is attached to
    identity :vm_id
    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this UEFI configuration is attached to
    attribute :computer_name

    # @!attribute [r] boot_order
    #   @todo should be mapped to VM models; HDD/NIC/DVD, needs additional work
    #   @return [Array<String>] the boot order of the VM
    attribute :boot_order
    # @!attribute console_mode
    #   @return [:Default, :COM1, :COM2, :None] where the console output should be directed
    attribute :console_mode, type: :hypervenum, values: %i[Default COM1 COM2 None]
    # @!attribute preferred_network_boot_protocol
    #   @return [:IPv4, :IPv6] the preferred IP protocol for PXE
    attribute :preferred_network_boot_protocol, type: :hypervenum, values: %i[IPv4 IPv6]
    # @!attribute secure_boot
    #   @return [:On, :Off] should secure boot be enabled
    #   @see ON_OFF_STATE_ENUM_VALUES
    attribute :secure_boot, type: :hypervenum, values: ON_OFF_STATE_ENUM_VALUES
    # @!attribute secure_boot_template
    #   @return [String] the template to use for the secure boot configuration
    #   @see Host#secure_boot_templates
    attribute :secure_boot_template
    # @!attribute secure_boot_template_id
    #   @return [String] the template id to use for the secure boot configuration
    #   @see Host#secure_boot_templates
    attribute :secure_boot_template_id
    # @!attribute pause_after_boot_failure
    #   @return [:On, :Off] should the VM pause after failing boot
    #   @see ON_OFF_STATE_ENUM_VALUES
    attribute :pause_after_boot_failure, type: :hypervenum, values: ON_OFF_STATE_ENUM_VALUES

    def update
      requires :vm_id

      merge_attributes(
        service.set_vm_firmware(
          computer_name:,
          vm_id:,

          enable_secure_boot: changed!(:secure_boot),
          secure_boot_template: changed!(:secure_boot_template),
          preferred_network_boot_protocol: changed!(:preferred_network_boot_protocol),
          console_mode: changed!(:console_mode),
          pause_after_boot_failure: changed!(:pause_after_boot_failure),

          _return_fields: self.class.attributes
        )
      )
    end

    def reload
      requires :vm_id

      data = service.get_vm_firmware(
        computer_name:,
        vm_id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end
  end
end
