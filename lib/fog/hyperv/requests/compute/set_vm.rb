module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm(options = {})
          run_shell('Set-VM', options)
        end
      end
    end
  end
end
