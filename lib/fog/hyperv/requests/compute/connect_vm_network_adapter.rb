module Fog
  module Compute
    class Hyperv
      class Real
        def connect_vm_network_adapter(options = {})
          run_shell('Connect-VMNetworkAdapter', options.merge(_skip_json: true))
        end
      end
    end
  end
end
