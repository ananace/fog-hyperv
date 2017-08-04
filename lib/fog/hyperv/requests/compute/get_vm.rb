module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm(options = {})
          run_shell('Get-VM', options)
        end
      end
    end
  end
end
