module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_firmware(options = {})
          requires options, :vm_name
          run_shell('Get-VMFirmware', options)
        end
      end
    end
  end
end

