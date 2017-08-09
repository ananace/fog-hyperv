module Fog
  module Compute
    class Hyperv
      class Real
        def stop_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Stop-VM
          run_shell('Stop-VM', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
