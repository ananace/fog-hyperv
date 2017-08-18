module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_dvd_drive(options = {})
          requires options, :vm_name
          run_shell('Get-VMDvdDrive', options)
        end
      end
    end
  end
end
