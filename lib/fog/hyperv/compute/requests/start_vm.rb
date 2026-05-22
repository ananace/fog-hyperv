# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def start_vm(id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: id }],
          ['$VM | Start-VM', options]
        ],
        skip_json: true,
        target_computer: computer_name
      )
    end
  end

  class Mock
    def start_vm(**_)
      true
    end
  end
end
