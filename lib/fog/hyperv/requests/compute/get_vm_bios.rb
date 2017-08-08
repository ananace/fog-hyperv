module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_bios(options = {})
          run_shell('Get-VMBios', options)
        end
      end
    end
  end
end

