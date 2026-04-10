# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def set_vm_dvd_drive(**options)
          requires options, :vm_name
          run_shell('Set-VMDvdDrive', **options)
        end
      end
    end
  end
end
