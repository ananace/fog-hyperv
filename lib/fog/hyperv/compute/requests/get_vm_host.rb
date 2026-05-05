# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_host(computer_name: nil, **options)
      run_cmd 'Get-VMHost', _target_computer: computer_name, **options
    end
  end
end
