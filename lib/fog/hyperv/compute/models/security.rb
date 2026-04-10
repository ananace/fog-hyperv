# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class Security < Fog::Hyperv::Model
        identity :id

        attribute :computer_name
        attribute :vm_name

        attribute :tpm_enabled, type: :boolean
        attribute :ksd_enabled, type: :boolean
        attribute :shielded, type: :boolean
        attribute :encrypt_state_and_vm_migration_traffic, type: :boolean
        attribute :virtualization_based_security_opt_out, type: :boolean
        attribute :bind_to_host_tpm, type: :boolean

        def key_protector
          service.get_vm_key_protector(
            computer_name: computer_name,
            vm_name: vm_name
          )[:value]
        end

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
