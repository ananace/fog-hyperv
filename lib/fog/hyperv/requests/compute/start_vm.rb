module Fog
  module Compute
    class Hyperv
      class Real
        def start_vm(options = {})
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Start-VM
          requires options, :name
          run_shell('Start-VM', options.merge(_skip_json: true)).exitcode.zero?
        end
      end
    end
  end
end
