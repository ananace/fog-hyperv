# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_dvd_drive(vm_id:, computer_name: nil, **options)
      _by_id = options.delete :id

      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMDvdDrive', { _by_id:, **options }]
        ],
        target_computer: computer_name
      )
    end
  end

  class Mock
    def get_vm_dvd_drive(**options)
      requires options, :vm_id

      handle_mock_response(args).find { |b| b[:vm_id].casecmp(args[:vm_id]).zero? }
    end
  end
end
