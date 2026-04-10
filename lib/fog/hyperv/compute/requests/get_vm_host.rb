# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def get_vm_host(**options)
          # TODO: Reject unavailable arguments?
          run_shell('Get-VMHost', **options)
        end
      end
    end
  end
end
