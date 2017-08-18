module Fog
  module Compute
    class Hyperv
      class Real
        def new_vhd(options = {})
          requires options, :path, :size_bytes
          run_shell('New-VHD', options)
        end
      end
    end
  end
end
