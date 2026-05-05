# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_hard_disk_drive(id:, vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$HDD = $VM | Get-VMHardDiskDrive', { _by_id: id }],
          ['$HDD | Set-VMHardDiskDrive', { passthru: true, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
