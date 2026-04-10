# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def set_vm(**options)
          requires options, :name
          run_shell('Set-VM', **options)
        end
      end
    end
  end
end
