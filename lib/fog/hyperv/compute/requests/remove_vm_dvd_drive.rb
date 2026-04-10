# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def remove_vm_dvd_drive(**options)
          requires options, :vm_name, :controller_number, :controller_location
          run_shell('Remove-VMDvdDrive', _skip_json: true, **options).exitcode.zero?
        end
      end
    end
  end
end
