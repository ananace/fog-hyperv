# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def disable_vm_tpm(**options)
          requires options, :vm_name
          run_shell('Disable-VMTPM', _skip_json: true, **options).exitcode.zero?
        end
      end
    end
  end
end
