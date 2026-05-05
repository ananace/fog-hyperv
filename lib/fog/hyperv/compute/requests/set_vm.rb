# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm(id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: }],
          ['$VM | Set-VM', { passthru: true, **options }]
        ],
        target_computer: computer_name
      )
    end
  end
end
