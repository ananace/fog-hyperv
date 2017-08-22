module Fog
  module Compute
    class Hyperv
      class Servers < Fog::Hyperv::Collection
        attribute :cluster

        model Fog::Compute::Hyperv::Server

        get_method :get_vm

        def search_attributes
          attrs = super
          attrs[:computer_name] = cluster.nodes.map { |n| n[:name] } if cluster
          attrs.delete :cluster
          attrs
        end

        def get(identity, filters = {})
          guid = identity =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/

          search = {}
          search[:id] = identity if guid
          search[:name] = identity unless guid

          super search.merge(filters)
        end
      end
    end
  end
end
