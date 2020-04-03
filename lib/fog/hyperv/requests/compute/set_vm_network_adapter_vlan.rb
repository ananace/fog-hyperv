# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_network_adapter_vlan(options = {})
          requires_one options, :vm_name, :management_os
          run_shell('Set-VMNetworkAdapterVlan', options)
        end
      end
    end
  end
end
