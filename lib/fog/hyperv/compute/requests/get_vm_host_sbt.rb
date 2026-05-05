# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    # Retrieve SecureBoot Templates for a VM Host
    def get_vm_host_sbt(computer_name:, **options)
      run_cmd '(Get-VMHost @Args).SecureBootTemplates', _target_computer: computer_name, **options
    end
  end
end
