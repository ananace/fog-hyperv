# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def enable_vm_integration_service(name:, vm_id:, computer_name: nil, **options)
      run_cmdlist(
        [
          ['$VM = Get-VM', { id: vm_id }],
          ['$VM | Enable-VMIntegrationService', { name: name, **options }]
        ],
        skip_json: true,
        target_computer: computer_name
      )
    end
  end
end
