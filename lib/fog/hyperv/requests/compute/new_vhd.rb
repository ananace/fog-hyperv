module Fog
  module Compute
    class Hyperv
      class Real
        def new_vhd(options = {})
          run_shell('New-VHD', options)
        end
      end
    end
  end
end
