# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def stop_vm(**options)
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Stop-VM
          requires options, :name
          run_shell('Stop-VM', _skip_json: true, **options).exitcode.zero?
        end
      end

      class Mock
        def stop_vm(**_)
          true
        end
      end
    end
  end
end
