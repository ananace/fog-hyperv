# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Switches < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Switch

    get_method :get_vm_switch

    attribute :computer_name

    def get(identifier, **filter)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      name = identifier unless id

      super(name:, id:, **filter)
    end
  end
end
