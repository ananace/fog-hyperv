# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def new_vm_switch(options = {})
          requires options, :name
          requires_one options, :net_adapter_name, :net_adapter_interface_description
          run_shell('New-VMSwitch', options)
        end
      end
    end
  end
end
