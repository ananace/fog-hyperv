# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/host'

module Fog
  module Hyperv
    class Compute
      class NetworkAdapters < Fog::Hyperv::VMCollection
        model Fog::Hyperv::Compute::NetworkAdapter

        get_method :get_vm_network_adapter

        def all(**filters)
          all = !(vm || filters.keys.any? { |k| k.to_s.start_with? 'vm_' })
          super(**filters.merge(all: all))
        end

        def get(name, filters = {})
          all = !(vm || filters.keys.any? { |k| k.to_s.start_with? 'vm_' })
          super(filters.merge(name: name, all: all))
        end
      end
    end
  end
end
