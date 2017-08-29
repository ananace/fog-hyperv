module Fog
  module Compute
    class Hyperv
      class Cluster < Fog::Hyperv::Model
        identity :id, type: :string

        attribute :description, type: :string
        attribute :domain, type: :string
        attribute :name, type: :string

        def nodes
          @nodes ||= [service.get_cluster_node(cluster: name, _return_fields: [:description, :name, :node_name])].flatten
        end

        def hosts
          @hosts ||= service.hosts computer_name: nodes.map { |n| n[:name] }
        end

        def servers
          @servers ||= service.servers cluster: self
        end

        def reload
          requires_one :domain, :name

          data = service.get_cluster(
            domain: domain,
            name: name,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )
          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
