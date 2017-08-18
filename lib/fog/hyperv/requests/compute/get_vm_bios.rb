module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_bios(options = {})
          requires options, :vm_name
          run_shell('Get-VMBios', options)
        end
      end
    end
  end
end

