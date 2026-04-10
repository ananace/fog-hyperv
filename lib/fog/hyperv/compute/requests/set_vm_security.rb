# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def set_vm_security(**options)
          requires options, :vm_name
          run_shell(
            'Set-VMSecurity',
            _always_include: %i[encrypt_state_and_vm_migration_traffic virtualization_based_security_opt_out],
            **options
          )
        end
      end
    end
  end
end
