module Fog
  module Compute
    class Hyperv
      class Real
        def remove_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Remove-VM
          run_shell('Remove-VM')
        end
      end
    end
  end
end
