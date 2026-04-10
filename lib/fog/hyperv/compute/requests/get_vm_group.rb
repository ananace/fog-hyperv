# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def get_vm_group(**options)
          requires_version '10.0'

          run_shell('Get-VMGroup', **options)
        end
      end

      class Mock
        def get_vm_group(**_options)
          requires_version '10.0'

          # TODO
          Fog::Mock.not_implemented
        end
      end
    end
  end
end
