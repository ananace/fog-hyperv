module Fog
  module Compute
    class Hyperv
      class Real
        def new_vm(options = {})
          run_shell('New-VM')
        end
      end
    end
  end
end
