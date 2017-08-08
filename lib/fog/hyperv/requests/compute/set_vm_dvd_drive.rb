module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_dvd_drive(options = {})
          run_shell('Set-VMDvdDrive', options)
        end
      end
    end
  end
end
