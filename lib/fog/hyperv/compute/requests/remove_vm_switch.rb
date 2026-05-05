# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def remove_vm_switch(id:, computer_name: nil, **options)
      run_cmd 'Remove-VMSwitch', _target_computer: computer_name, _by_id: id, _skip_json: true, **options
    end
  end
end
