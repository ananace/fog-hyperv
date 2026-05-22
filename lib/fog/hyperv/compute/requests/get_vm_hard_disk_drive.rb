# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_hard_disk_drive(vm_id:, computer_name: nil, **options)
      by_id = options.delete :id
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMHardDiskDrive', { _by_id: by_id, **options }]
        ],
        target_computer: computer_name
      )
    end
  end

  class Mock
    def get_vm_hard_disk_drive(**args)
      requires args, :vm_id

      handle_mock_response(args).find { |b| b[:vm_id].casecmp(args[:vm_id]).zero? }
    end
  end
end
