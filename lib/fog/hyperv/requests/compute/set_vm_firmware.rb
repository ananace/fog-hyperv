module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm_firmware(options = {})
          run_shell('Set-VMFirmware', options)
        end
      end
    end
  end
end

