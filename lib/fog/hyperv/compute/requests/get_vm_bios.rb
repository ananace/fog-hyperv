# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_bios(vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Get-VMBios', options]
        ],
        target_computer: computer_name
      )
    end
  end

  class Mock
    def get_vm_bios(**args)
      handle_mock_response(args).find { |b| b[:vm_id].casecmp(args[:vm_id]).zero? }
    end
  end
end
