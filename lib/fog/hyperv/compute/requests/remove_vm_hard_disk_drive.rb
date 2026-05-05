# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def remove_vm_hard_disk_drive(vm_id:, id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$HDD = $VM | Get-VMHardDiskDrive', { _by_id: id }],
          ['$HDD | Remove-VMHardDiskDrive', { force: true, **options }]
        ],
        skip_json: true,
        target_computer: computer_name
      )
    end
  end
end
