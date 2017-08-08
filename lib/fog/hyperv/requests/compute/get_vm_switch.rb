module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_switch(options = {})
          run_shell('Get-VMSwitch', options)
        end
      end
    end
  end
end

