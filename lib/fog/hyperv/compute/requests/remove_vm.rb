# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def remove_vm(**options)
          # TODO: Handle -VMId/-Id too;
          #
          #   Get-VM -Id <guid> | Remove-VM
          requires options, :name
          run_shell('Remove-VM', _skip_json: true, **options.merge(force: true)).exitcode.zero?
        end
      end
    end
  end
end
