# frozen_string_literal: true

class Fog::Hyperv::Compute
  # Configuration for the BIOS settings of a VM
  #
  # @see https://learn.microsoft.com/en-us/powershell/module/hyper-v/set-vmbios for set-request
  class Bios < Fog::Hyperv::Model
    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this BIOS configuration is attached to
    identity :vm_id, type: :string

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this BIOS configuration is attached to
    attribute :computer_name, type: :string

    # attribute :is_deleted, type: :boolean
    # @!attribute num_lock_enabled
    #   @return [Boolean] if num-lock should be enabled on boot
    attribute :num_lock_enabled, type: :boolean
    # @!attribute startup_order
    #   @note Hyper-V only really allows reordering these entries, not adding/removing from the list
    #   @return [Array<Symbol>] the boot order of the VM
    #   @see Fog::Hyperv::BOOT_DEVICE_ENUM_VALUES
    #   @example Set legacy net boot as default - if possible
    #     netboot = bios.startup_order.delete :LegacyNetworkAdapter
    #     bios.startup_order.unshift netboot if netboot
    #     bios.save
    attribute :startup_order, type: :hypervenumarray, values: Fog::Hyperv::BOOT_DEVICE_ENUM_VALUES

    # Save any modifications to Hyper-V
    def update
      requires :vm_id

      # raise ArgumentError, 'Startup order can only be rearranged, not modified' \
      #   if changed?(:startup_order) && startup_order.sort != old.startup_order.sort

      changes = {
        startup_order: changed!(:startup_order)
      }.compact
      changes[num_lock_enabled ? :enable_num_lock : :disable_num_lock] = true if changed?(:num_lock_enabled)
      return self unless changes.any?

      data = service.set_vm_bios(
        computer_name: computer_name,
        vm_id: vm_id,

        **changes,

        _return_fields: self.class.attributes
      )

      merge_attributes(data)
    end

    # Reload attributes from Hyper-V
    def reload
      requires :vm_id

      data = service.get_vm_bios(
        computer_name: computer_name,
        vm_id: vm_id,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end
  end
end
