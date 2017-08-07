module Fog
  module Compute
    class Hyperv
      class Real
        def remove_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Remove-VM
          run_shell('Remove-VM', options.merge(_skip_json: true))
        end
      end
    end
  end
end
