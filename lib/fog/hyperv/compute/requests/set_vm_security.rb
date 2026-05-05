# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_security(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Set-VMSecurity', {
            _always_include: %i[encrypt_state_and_vm_migration_traffic virtualization_based_security_opt_out], passthru: true, **options
          }]
        ],
        target_computer: computer_name
      )
    end
  end
end
