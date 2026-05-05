# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Servers < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Server

    get_method :get_vm

    def get(identifier, **filters)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      name = identifier unless id

      super(name:, id:, **filters)
    end
  end
end
