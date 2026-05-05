# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_firmware(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMFirmware', options]
        ],
        target_computer: computer_name
      )
    end
  end

  class Mock
    def get_vm_firmware(**args)
      handle_mock_response(args).find { |b| b[:vm_name].casecmp(args[:vm_name]).zero? }
    end
  end
end
