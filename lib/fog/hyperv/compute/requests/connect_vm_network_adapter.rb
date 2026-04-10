# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def connect_vm_network_adapter(**options)
          requires options, :vm_name, :switch_name
          run_shell('Connect-VMNetworkAdapter', _skip_json: true, **options).exitcode.zero?
        end
      end
    end
  end
end
