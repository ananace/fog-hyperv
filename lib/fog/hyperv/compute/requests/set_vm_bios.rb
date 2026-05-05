# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_bios(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Set-VMBios', { passthru: true, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
