# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class NetworkAdapters < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::NetworkAdapter

        get_method :get_vm_network_adapter

        def all(filters = {})
          all = !(vm || filters.keys.any? { |k| k.to_s.start_with? 'vm_' })
          super filters.merge(all: all)
        end

        def get(name, filters = {})
          all = !(vm || filters.keys.any? { |k| k.to_s.start_with? 'vm_' })
          super filters.merge(name: name, all: all)
        end
      end
    end
  end
end
