# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Clusters < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Cluster

    get_method :get_cluster

    def get(name, **filters)
      super(name:, **filters)
    end
  end
end
