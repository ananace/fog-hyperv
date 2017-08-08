module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_firmware(options = {})
          run_shell('Get-VMFirmware', options)
        end
      end
    end
  end
end

