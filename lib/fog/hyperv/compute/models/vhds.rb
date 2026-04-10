# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/vhd'

module Fog
  module Hyperv
    class Compute
      class Vhds < Fog::Hyperv::VMCollection
        model Fog::Hyperv::Compute::Vhd
        match_on :vm_id

        get_method :get_vhd

        def get(path, filters = {})
          super(search_attributes.merge(filters.merge(path: path)))
        end
      end
    end
  end
end
