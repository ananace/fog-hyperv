# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def disconnect_vm_network_adapter(**options)
          requires :vm_name
          run_shell('Disconnect-VMNetworkAdapter', _skip_json: true, **options).exitcode.zero?
        end
      end
    end
  end
end
