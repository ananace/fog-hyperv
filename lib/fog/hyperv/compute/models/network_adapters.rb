# frozen_string_literal: true

class Fog::Hyperv::Compute
  class NetworkAdapters < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::NetworkAdapter

    get_method :get_vm_network_adapter

    attribute :computer_name
    attribute :vm_id

    def all(filters = {})
      all = true
      all = false if @vm || vm_id || filters.key?(:management_os)

      super({ all: }.merge(filters))
    end

    def get(identifier, **filters)
      id = identifier if identifier =~ /\Amicrosoft:#{Fog::Hyperv::GUID}\\#{Fog::Hyperv::GUID}\z/i
      name = identifier unless id

      super(name:, _by_id: id, **filters)
    end
  end
end
