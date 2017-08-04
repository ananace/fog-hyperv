module Fog
  module Compute
    class Hyperv
      class Real
        def start_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Start-VM
          run_shell('Start-VM', options)
        end
      end
    end
  end
end
