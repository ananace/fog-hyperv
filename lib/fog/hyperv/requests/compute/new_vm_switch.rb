module Fog
  module Compute
    class Hyperv
      class Real
        def new_vm_switch(options = {})
          run_shell('New-VMSwitch', options)
        end
      end
    end
  end
end
