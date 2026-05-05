# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def add_vm_dvd_drive(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Add-VMDvdDrive', { passthru: true, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
