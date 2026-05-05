# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_key_protector(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Set-VMKeyProtector', options]
        ],
        target_computer: computer_name
      )
    end
  end
end
