# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def add_vm_dvd_disk_drive(options = {})
          requires options, :vm_name
          run_shell('Add-VMDvdDrive', options)
        end
      end
    end
  end
end
