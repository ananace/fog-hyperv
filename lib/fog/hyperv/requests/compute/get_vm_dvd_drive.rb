module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_dvd_drive(options = {})
          requires options, :vm_name
          run_shell('Get-VMDvdDrive', options)
        end
      end

      class Mock
        def get_vm_dvd_drive(options = {})
          requires options, :vm_name

          handle_mock_response(args).find { |b| b[:vm_name].casecmp(args[:vm_name]).zero? }
        end
      end
    end
  end
end
