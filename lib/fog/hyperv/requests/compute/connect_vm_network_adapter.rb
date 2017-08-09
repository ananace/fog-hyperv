module Fog
  module Compute
    class Hyperv
      class Real
        def connect_vm_network_adapter(options = {})
          run_shell('Connect-VMNetworkAdapter', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
