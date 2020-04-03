# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Cluster < Fog::Hyperv::Model
        identity :id, type: :string

        attribute :description, type: :string
        attribute :domain, type: :string
        attribute :name, type: :string

        # def initialize(attrs = {})
        #   super

          # @collections = {}
          # self.class.ensure_collections!
        # end

        def nodes
          attributes[:nodes] ||= id.nil? ? [] : [service.get_cluster_node(cluster: name, _return_fields: [:description, :name, :node_name])].flatten
        end

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

        # def self.ensure_collections!
        #   return if @collections
        #   @collections = true

        #   Fog::Compute::Hyperv.collections.each do |coll|
        #     # Don't recurse on hosts
        #     next if coll == :hosts

        #     coll_name = coll.to_s.split('_').map(&:capitalize).join
        #     klass = Fog::Compute::Hyperv.const_get(coll_name)
        #     next if klass.requires?(:vm)

        #     define_method coll do
        #       @collections[coll] ||= service.send(coll, cluster: self)
        #     end
        #   end
        # end
      end
    end
  end
end
