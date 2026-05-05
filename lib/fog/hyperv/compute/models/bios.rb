# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Bios < Fog::Hyperv::Model
    # Possible boot devices
    # @note Defined by Microsoft.HyperV.PowerShell.BootDevice
    BIOS_BOOT_DEVICE = %i[
      Floppy CD IDE LegacyNetworkAdapter NetworkAdapter VHD
    ].freeze

    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this BIOS configuration is attached to
    identity :vm_id, type: :string

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this BIOS configuration is attached to
    attribute :computer_name, type: :string

    # attribute :is_deleted, type: :boolean
    # @!attribute num_lock_enabled
    #   @return [Boolean] should num-lock be enabled on boot
    attribute :num_lock_enabled, type: :boolean
    # @!attribute startup_order
    #   @return [Array<Symol>] the boot order of the VM
    #   @see BIOS_BOOT_DEVICE
    attribute :startup_order, type: :hypervenumarray, values: BIOS_BOOT_DEVICE

    def update
      requires :vm_id

      raise ArgumentError, 'Startup order can only be rearranged, not modified' \
        if changed?(:startup_order) && startup_order.sort != old.startup_order.sort

      data = service.set_vm_bios(
        computer_name:,
        vm_id:,

        disable_num_lock: changed?(:num_lock_enabled) && !num_lock_enabled,
        enable_num_lock: changed?(:num_lock_enabled) && num_lock_enabled,
        startup_order: changed!(:startup_order),

        _return_fields: self.class.attributes
      )

      merge_attributes(data)
    end

    def reload
      requires :vm_id

      data = service.get_vm_bios(
        computer_name:,
        vm_id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end
  end
end
