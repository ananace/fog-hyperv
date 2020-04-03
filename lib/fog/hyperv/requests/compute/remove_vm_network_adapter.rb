# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def remove_vm_network_adapter(options = {})
          requires_one options, :vm_name, :management_os
          run_shell('Remove-VMNetworkAdapter', options)
        end
      end
    end
  end
end
