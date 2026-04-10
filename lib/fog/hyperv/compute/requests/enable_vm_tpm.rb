# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def enable_vm_tpm(**options)
          requires options, :vm_name
          run_shell('Enable-VMTPM', _skip_json: true, **options).exitcode.zero?
        end
      end
    end
  end
end
