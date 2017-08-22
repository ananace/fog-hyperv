module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_group(options = {})
          requires_version '10.0'

          run_shell('Get-VMGroup', options)
        end
      end
    end
  end
end

