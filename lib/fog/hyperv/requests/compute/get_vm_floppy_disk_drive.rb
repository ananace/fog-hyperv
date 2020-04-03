# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_floppy_disk_drive(options = {})
          requires options, :vm_name
          run_shell('Get-VMFloppyDiskDrive', options)
        end
      end

      class Mock
        def get_vm_floppy_disk_drive(options = {})
          requires options, :vm_name

          handle_mock_response(args).find { |b| b[:vm_name].casecmp(args[:vm_name]).zero? }
        end
      end
    end
  end
end
