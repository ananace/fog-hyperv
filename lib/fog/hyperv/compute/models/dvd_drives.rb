# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/dvd_drive'

module Fog
  module Hyperv
    class Compute
      class DvdDrives < Fog::Hyperv::VMCollection
        model Fog::Hyperv::Compute::DvdDrive
        requires_vm

        get_method :get_vm_dvd_drive
      end
    end
  end
end
