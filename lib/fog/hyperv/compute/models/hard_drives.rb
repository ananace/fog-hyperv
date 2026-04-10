# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/hard_drive'

module Fog
  module Hyperv
    class Compute
      class HardDrives < Fog::Hyperv::VMCollection
        model Fog::Hyperv::Compute::HardDrive

        get_method :get_vm_hard_disk_drive
      end
    end
  end
end
