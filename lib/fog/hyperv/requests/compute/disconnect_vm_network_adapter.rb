# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def disconnect_vm_network_adapter(options = {})
          requires :vm_name
          run_shell('Disconnect-VMNetworkAdapter', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
