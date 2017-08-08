module Fog
  module Compute
    class Hyperv
      class Real
        def get_vhd(options = {})
          run_shell('Get-VHD', options)
        end
      end
    end
  end
end
