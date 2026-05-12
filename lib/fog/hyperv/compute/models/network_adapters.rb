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

      raise ArgumentError, 'Must provide a name or GUID' if (id.nil? || id.empty?) && (name.nil? || name.empty?)

      super(name:, _by_id: id, **filters)
    end

    protected

    def search_attributes
      super.merge(
        _return_fields: model.attributes - %i[vlan_setting]
      )
    end
  end
end
