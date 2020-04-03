# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_firmware(options = {})
          requires options, :vm_name
          run_shell('Get-VMFirmware', options)
        end
      end

      class Mock
        def get_vm_firmware(args = {})
          handle_mock_response(args).find { |b| b[:vm_name].casecmp(args[:vm_name]).zero? }
        end
      end
    end
  end
end

