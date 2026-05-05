# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Cluster < Fog::Hyperv::Model
    # @!attribute [r] id
    #   @return [String] the GUID of the cluster
    identity :id, type: :string

    # @!attribute [r] description
    #   @return [String] the description of the cluster
    attribute :description, type: :string
    # @!attribute [r] domain
    #   @return [String] the domain of the cluster
    attribute :domain, type: :string
    # @!attribute [r] name
    #   @return [String] the name of the cluster
    attribute :name, type: :string

    # @!attribute [r] hosts
    #   @return [Array<Host>] the hosts in the cluster
    def hosts
      return [] unless persisted?

      cluster_nodes.map { |n| service.hosts.get(n[:name]) }
    end

    def reload
      requires :id

      data = service.get_cluster(
        id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data.attributes)
    end

    private

    def cluster_nodes
      return [] unless persisted?

      requires :id

      [
        service.get_cluster_node(
          id:,

          _return_fields: %i[name]
        )
      ].flatten
    end
  end
end
