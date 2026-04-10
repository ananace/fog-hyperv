# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def start_vm(**options)
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Start-VM
          requires options, :name
          run_shell('Start-VM', _skip_json: true, **options).exitcode.zero?
        end
      end

      class Mock
        def start_vm(**_)
          true
        end
      end
    end
  end
end
