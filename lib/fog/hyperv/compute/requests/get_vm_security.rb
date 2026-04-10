# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def get_vm_security(**options)
          run_shell('Get-VMSecurity', **options)
        end
      end
    end
  end
end
