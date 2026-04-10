# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Cluster < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] The GUID of the cluster
        identity :id, type: :string

        # @!attribute [r] description
        #   @return [String] The description of the cluster
        attribute :description, type: :string
        # @!attribute [r] domain
        #   @return [String] The domain of the cluster
        attribute :domain, type: :string
        # @!attribute [r] domain
        #   @return [String] The name of the cluster
        attribute :name, type: :string

        # @!attribute [r] nodes
        #   @return [Array<Hash>] The nodes in the cluster
        def nodes
          attributes[:nodes] ||= if id.nil?
                                   []
                                 else
                                   [service.get_cluster_node(cluster: name,
                                                             _return_fields: %i[
                                                               description name node_name
                                                             ])].flatten
                                 end
        end

        # @!attribute [r] hosts
        #   @return [Array<Host>] The hosts in the cluster
        def hosts
          attributes[:hosts] ||= id.nil? ? [] : nodes.map { |n| service.hosts.get(n[:name]) }
        end

        def reload
          requires_one :domain, :name

          data = service.get_cluster(
            domain: domain,
            name: name,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )

          attributes[:nodes] = nil
          attributes[:hosts] = nil

          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
