# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def add_vm_network_adapter(**options)
          requires_one options, :vm_name, :management_os
          run_shell('Add-VMNetworkAdapter', _always_include: %i[is_legacy], **options)
        end
      end
    end
  end
end
