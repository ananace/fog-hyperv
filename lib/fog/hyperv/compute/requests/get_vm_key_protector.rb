# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    # Retrieve SecureBoot Templates for a VM Host
    def get_vm_key_protector(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMKeyProtector', options]
        ],
        target_computer: computer_name
      )
    end
  end
end
