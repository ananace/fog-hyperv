module Fog
  module Compute
    class Hyperv
      class Real
        def disconnect_vm_network_adapter(options = {})
          run_shell('Disconnect-VMNetworkAdapter', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
