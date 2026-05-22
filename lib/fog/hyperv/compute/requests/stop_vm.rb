# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def stop_vm(id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: id }],
          ['$VM | Stop-VM', { force: true, **options }]
        ],
        skip_json: true,
        target_computer: computer_name
      )
    end
  end

  class Mock
    def stop_vm(**_)
      true
    end
  end
end
