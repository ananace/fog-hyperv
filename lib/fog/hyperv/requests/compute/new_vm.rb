module Fog
  module Compute
    class Hyperv
      class Real
        def new_vm(options = {})
          options[:memory_startup_bytes] = options.delete :memory_startup if options.key? :memory_startup

          run_shell('New-VM', options)
        end
      end
    end
  end
end
