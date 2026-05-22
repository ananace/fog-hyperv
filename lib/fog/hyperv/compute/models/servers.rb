# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Servers < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Server

    get_method :get_vm

    def get(identifier, **filters)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      name = identifier unless id

      raise ArgumentError, 'Must provide a name or GUID' if (id.nil? || id.empty?) && (name.nil? || name.empty?)

      super(name: name, id: id, **filters)
    end
  end
end
