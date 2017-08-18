module Fog
  module Compute
    class Hyperv
      class Real
        def set_vm(options = {})
          requires options, :name
          run_shell('Set-VM', options)
        end
      end
    end
  end
end
