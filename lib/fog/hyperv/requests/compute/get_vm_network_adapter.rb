module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_network_adapter(options = {})
          requires_one options, :vm_name, :all, :management_os
          run_shell('Get-VMNetworkAdapter', options)
        end
      end
    end
  end
end
