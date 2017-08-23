module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_bios(options = {})
          requires options, :vm_name
          run_shell('Get-VMBios', options)
        end
      end

      class Mock
        def get_vm_bios(args = {})
          requires args, :vm_name

          handle_mock_response(args).find { |b| b[:vm_name].casecmp(args[:vm_name]).zero? }
        end
      end
    end
  end
end

