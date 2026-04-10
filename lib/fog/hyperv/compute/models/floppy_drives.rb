# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/floppy_drive'

module Fog
  module Hyperv
    class Compute
      class FloppyDrives < Fog::Hyperv::VMCollection
        model Fog::Hyperv::Compute::FloppyDrive
        requires_vm

        get_method :get_vm_floppy_disk_drive
      end
    end
  end
end
