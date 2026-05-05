# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def disable_vm_tpm(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Disable-VMTPM', options]
        ],
        skip_json: true,
        target_computer: computer_name
      )
    end
  end
end
