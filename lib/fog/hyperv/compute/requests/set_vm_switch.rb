# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_switch(id:, computer_name: nil, **options)
      run_cmd 'Set-VMSwitch', _target_computer: computer_name, _by_id: id, passthru: true, **options
    end
  end
end
