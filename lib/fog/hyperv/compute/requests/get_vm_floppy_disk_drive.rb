# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_floppy_disk_drive(vm_id:, computer_name: nil, **options)
      by_id = options.delete :id
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMFloppyDiskDrive', { _by_id: by_id, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
