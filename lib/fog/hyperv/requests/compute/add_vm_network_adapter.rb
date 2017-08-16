module Fog
  module Compute
    class Hyperv
      class Real
        def add_vm_network_adapter(options = {})
          run_shell('Add-VMNetworkAdapter', options)
        end
      end
    end
  end
end
