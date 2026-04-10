# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def set_vm_network_adapter(**options)
          requires_one options, :vm_name, :management_os
          run_shell('Set-VMNetworkAdapter', **options)
        end
      end
    end
  end
end
