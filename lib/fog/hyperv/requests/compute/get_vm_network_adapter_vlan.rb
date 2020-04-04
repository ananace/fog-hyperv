# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_network_adapter_vlan(options = {})
          run_shell('Get-VMNetworkAdapterVlan', options)
        end
      end

      class Mock
        def get_vm_network_adapter_vlan(args = {})
          data = handle_mock_response(args)
          if args[:vm_name]
            data.find { |i| i[:vm_name].casecmp(args[:vm_name]).zero? }
          elsif args[:management_os]
            data.find { |i| i[:is_management_os] }
          else
            data
          end
        end
      end
    end
  end
end
