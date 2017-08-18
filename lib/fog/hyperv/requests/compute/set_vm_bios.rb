module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_bios(options = {})
          requires options, :vm_name
          run_shell('Set-VMBios', options)
        end
      end
    end
  end
end

