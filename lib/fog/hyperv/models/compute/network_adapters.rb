# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class NetworkAdapters < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::NetworkAdapter

        get_method :get_vm_network_adapter

        def all(filters = {})
          super filters.merge(all: !vm)
        end

        def get(name, filters = {})
          super filters.merge(name: name, all: !vm)
        end
      end
    end
  end
end
