# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Clusters < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::Cluster

        get_method :get_cluster

        def get(name, filters = {})
          super(filters.merge(name: name))
        end
      end
    end
  end
end
