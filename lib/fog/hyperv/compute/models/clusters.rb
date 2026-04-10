# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/cluster'

module Fog
  module Hyperv
    class Compute
      class Clusters < Fog::Hyperv::VMCollection
        model Fog::Hyperv::Compute::Cluster

        get_method :get_cluster

        def get(name, filters = {})
          super(filters.merge(name: name))
        end
      end
    end
  end
end
