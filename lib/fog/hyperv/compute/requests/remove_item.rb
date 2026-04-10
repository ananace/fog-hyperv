# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def remove_item(**options)
          # TODO: Really lock this method down, validation is good.
          requires options, :path
          run_shell('Remove-Item', _skip_json: true, **options.merge(force: true)).exitcode.zero?
        end
      end
    end
  end
end
