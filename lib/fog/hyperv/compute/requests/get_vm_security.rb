# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_security(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMSecurity', options]
        ],
        target_computer: computer_name
      )
    end
  end
end
