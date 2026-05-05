# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def rename_vm(id:, new_name:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: }],
          ['$VM | Rename-VM', { new_name:, **options }]
        ],
        target_computer: computer_name,
        skip_json: true
      )
    end
  end
end
