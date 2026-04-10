# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def set_vm_switch(**options)
          requires options, :name
          run_shell('Set-VMSwitch', **options)
        end
      end
    end
  end
end
