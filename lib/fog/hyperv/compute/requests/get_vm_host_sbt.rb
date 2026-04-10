# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        # Retrieve SecureBoot Templates for a VM Host
        def get_vm_host_sbt(**options)
          run_shell('(Get-VMHost @Args).SecureBootTemplates', **options)
        end
      end
    end
  end
end
