module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_network_adapter(options = {})
          requires_one options, :vm_name, :all, :management_os
          run_shell('Get-VMNetworkAdapter', options)
        end
      end

      class Mock
        def get_vm_network_adapter(args = {})
          requires_one args, :vm_name, :all, :management_os

          data = handle_mock_response(args)
          if args[:all]
            data
          elsif args[:vm_name]
            data.find { |i| i[:vm_name].casecmp(args[:vm_name]).zero? }
          elsif args[:management_os]
            data.find { |i| i[:is_management_os] }
          end
        end
      end
    end
  end
end
