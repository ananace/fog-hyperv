module Fog
  module Compute
    class Hyperv
      class Clusters < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::Cluster

        get_method :get_cluster
      end
    end
  end
end
