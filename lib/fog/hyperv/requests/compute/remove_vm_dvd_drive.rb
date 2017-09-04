module Fog
  module Compute
    class Hyperv
      class Real
        def remove_vm_dvd_drive(options = {})
          requires options, :vm_name, :controller_number, :controller_location
          run_shell('Remove-VMDvdDrive', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
