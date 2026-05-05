# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Vhds < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Vhd

    get_method :get_vhd

    attribute :computer_name

    def get(identifier, **filters)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      path = identifier unless id

      super(disk_identifier: id, path:, **filters)
    end
  end
end
