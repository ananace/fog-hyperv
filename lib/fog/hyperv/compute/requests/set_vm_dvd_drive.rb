# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_dvd_drive(id:, vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$DVD = $VM | Get-VMDvdDrive', { _by_id: id }],
          ['$DVD | Set-VMDvdDrive', { passthru: true, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
