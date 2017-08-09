module Fog
  module Compute
    class Hyperv
      class Real
        def restart_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Start-VM
          run_shell('Restart-VM', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
