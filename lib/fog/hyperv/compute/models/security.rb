# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      # Security settings for a generation 2 (UEFI) VM
      #
      # @see https://learn.microsoft.com/en-us/windows/win32/hyperv_v2/msvm-securitysettingdata WMI definitions
      class Security < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] the GUID of this security configuration
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] the name of the computer running the VM that this security configuration is attached to
        attribute :computer_name
        # @!attribute [r] vm_name
        #   @return [String] the name of the VM this security configuration is attached to
        attribute :vm_name

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

        # @return [String, null] the key protector encryption key if set
        def key_protector
          service.get_vm_key_protector(
            computer_name: computer_name,
            vm_name: vm_name
          )[:value]
        end

        # Sets a new key protector for the VM
        # @param protector [:new, :local, :last, String] the key protector to set.
        #   +:new+/+:local+ will generate a new host-local encryption key,
        #   +:last+ will restore the last successfully used encryption key
        def key_protector=(protector)
          protector = case protector
                      when :new, :local
                        { new_local_key_protector: true }
                      when :last
                        { restore_last_known_good_key_protector: true }
                      else
                        { key_protector: protector }
                      end

          service.set_vm_key_protector(
            computer_name: computer_name,
            vm_name: vm_name,

            **protector,

            _skip_json: true
          )
        end

        def save
          requires :computer_name, :vm_name

          raise Fog::Hyperv::Errors::ServiceError, "Can't create loose Security instances" unless persisted?

          data = {}
          if tpm_enabled != old.tpm_enabled
            meth = tpm_enabled ? :enable_vm_tpm : :disable_vm_tpm
            service.public_send(meth, vm_name: vm_name)
            data[:tpm_enabled] = tpm_enabled
          end

          if changed?(:encrypt_state_and_vm_migration_traffic) || changed?(:virtualization_based_security_opt_out)
            data[:encrypt_state_and_vm_migration_traffic] = changed! :encrypt_state_and_vm_migration_traffic
            data[:virtualization_based_security_opt_out] = changed! :virtualization_based_security_opt_out

            service.set_vm_security(
              computer_name: old.computer_name,
              vm_name: vm_name,

              encrypt_state_and_vm_migration_traffic: changed!(encrypt_state_and_vm_migration_traffic),
              virtualization_based_security_opt_out: changed!(virtualization_based_security_opt_out),

              _skip_json: true
            )
          end
          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          requires :computer_name, :vm_name

          data = service.get_vm_security(
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
