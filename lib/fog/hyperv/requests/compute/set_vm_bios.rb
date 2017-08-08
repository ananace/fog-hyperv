module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_bios(options = {})
          run_shell('Set-VMBios', options)
        end
      end
    end
  end
end

