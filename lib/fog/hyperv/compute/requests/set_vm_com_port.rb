# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_com_port(id:, vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$COM = $VM | Get-VMComPort', { _by_id: id }],
          ['$COM | Set-VMComPort', { passthru: true, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
