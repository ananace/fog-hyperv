# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def new_vm_switch(name:, computer_name: nil, **options)
      requires_one options, :net_adapter_name, :net_adapter_interface_description

      run_cmd 'New-VMSwitch', _target_computer: computer_name, name: name, **options
    end
  end
end
