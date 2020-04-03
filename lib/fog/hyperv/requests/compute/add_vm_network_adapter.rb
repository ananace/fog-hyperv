# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def add_vm_network_adapter(options = {})
          requires_one options, :vm_name, :management_os
          run_shell('Add-VMNetworkAdapter', options.merge(_always_include: [:is_legacy]))
        end
      end
    end
  end
end
