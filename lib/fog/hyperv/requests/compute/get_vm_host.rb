module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_host(options = {})
          # TODO: Reject unavailable arguments?
          run_shell('Get-VMHost', options)
        end
      end
    end
  end
end

