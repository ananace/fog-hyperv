# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def rename_vm_switch(id:, new_name:, computer_name: nil, **options)
      run_cmd 'Rename-VMSwitch', new_name:, _target_computer: computer_name, _by_id: id, _skip_json: true, **options
    end
  end
end
