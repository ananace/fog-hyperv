# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def remove_vm_hard_disk_drive(**options)
          requires options, :vm_name, :controller_type, :controller_number, :controller_location
          run_shell('Remove-VMHardDiskDrive', _skip_json: true, **options).exitcode.zero?
        end
      end
    end
  end
end
