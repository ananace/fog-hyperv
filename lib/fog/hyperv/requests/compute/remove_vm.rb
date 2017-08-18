module Fog
  module Compute
    class Hyperv
      class Real
        def remove_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Remove-VM
          requires options, :name
          run_shell('Remove-VM', options.merge(force: true, _skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
