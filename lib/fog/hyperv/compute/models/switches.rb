# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/switch'

module Fog
  module Hyperv
    class Compute
      class Switches < Fog::Hyperv::ComputerCollection
        model Fog::Hyperv::Compute::Switch

        get_method :get_vm_switch

        def get(name, filters = {})
          super(filters.merge(name: name))
        end
      end
    end
  end
end
