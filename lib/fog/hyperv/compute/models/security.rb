# frozen_string_literal: true

class Fog::Hyperv::Compute
  # Security settings for a generation 2 (UEFI) VM
  #
  # @see https://learn.microsoft.com/en-us/windows/win32/hyperv_v2/msvm-securitysettingdata WMI definitions
  class Security < Fog::Hyperv::Model
    # @!attribute tpm_enabled
    #   @return [Boolean] is a vTPM enabled for the VM
    attribute :tpm_enabled, type: :boolean
    # @!attribute [r] ksd_enabled
    #   @return [Boolean] is a key storage device enabled for the VM
    attribute :ksd_enabled, type: :boolean
    # @!attribute [r] shielded
    #   @return [Boolean] is the VM shielded
    attribute :shielded, type: :boolean
    # @!attribute encrypt_state_and_vm_migration_traffic
    #   @return [Boolean] should VM state and migration traffic be encrypted
    attribute :encrypt_state_and_vm_migration_traffic, type: :boolean
    # @!attribute virtualization_based_security_opt_out
    #   @return [Boolean] should virtualization-based securty be opted out of for the VM
    attribute :virtualization_based_security_opt_out, type: :boolean
    # @!attribute [r] bind_to_host_tpm
    #   @return [Boolean] is the VM bound to the host TPM
    attribute :bind_to_host_tpm, type: :boolean

    # @!attribute [r] vm
    #   @return [Server] the VM this security configuration is attached to
    has_one :vm, :servers

    alias identity :hash

    # @!attribute [r] key_protector
    # @return [String, null] the key protector encryption key
    # @see change_key_protector
    def key_protector
      requires :vm

      @key_protector ||= service.get_vm_key_protector(
        computer_name: vm.computer_name,
        vm_id: vm.id
      )[:value]
    end

    # Change the key protector for a VM
    # @param protector [:new, :local, :last, String] the key protector to set.
    #   +:new+/+:local+ will generate a new host-local encryption key,
    #   +:last+ will restore the last successfully used encryption key
    # @return [String] the binary key protector that was set
    # @note a VM key protector can not be removed once set, only changed
    def change_key_protector(protector)
      requires :vm

      protector = case protector
                  when :new, :local
                    { new_local_key_protector: true }
                  when :last
                    { restore_last_known_good_key_protector: true }
                  else
                    { key_protector: protector }
                  end

      service.set_vm_key_protector(
        computer_name: vm.computer_name,
        vm_id: vm.id,

        **protector
      )
      @key_protector = nil
      true
    end

    def update
      requires :vm

      if tpm_enabled != old.tpm_enabled
        meth = tpm_enabled ? :enable_vm_tpm : :disable_vm_tpm
        service.public_send(meth, vm_id: vm.id)
      end

      return self unless dirty?

      merge_attributes(
        service.set_vm_security(
          computer_name: old.vm.computer_name,
          vm_id: old.vm.id,

          encrypt_state_and_vm_migration_traffic:,
          virtualization_based_security_opt_out:,

          _return_fields: self.class.attributes
        )
      )
    end

    def reload
      requires :vm

      data = service.get_vm_security(
        computer_name: vm.computer_name,
        vm_id: vm.id,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end

    private

    def merge_attributes(attributes = {})
      attributes[:vm] ||= @vm

      super
    end
  end
end
