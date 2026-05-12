# frozen_string_literal: true

class Fog::Hyperv::Compute
  # A collection of clusters known by Hyper-V
  class Clusters < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Cluster

    get_method :get_cluster

    # Get an instance of a cluster by name or id
    # @param identifier [String] the name or GUID of the cluster
    def get(identifier, **filters)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      name = identifier unless id

      raise ArgumentError, 'Must provide a name or GUID' if (id.nil? || id.empty?) && (name.nil? || name.empty?)

      super(name:, _by_id: id, **filters)
    end
  end
end
