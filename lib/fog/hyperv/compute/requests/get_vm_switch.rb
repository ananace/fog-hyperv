# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_switch(computer_name: nil, **options)
      id = options.delete :id
      run_cmd 'Get-VMSwitch', _by_id: id, _target_computer: computer_name, **options
    end
  end
end
