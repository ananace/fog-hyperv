# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Switches < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Switch

    get_method :get_vm_switch

    attribute :computer_name

    def get(identifier, **filter)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      name = identifier unless id

      raise ArgumentError, 'Must provide a name or GUID' if (id.nil? || id.empty?) && (name.nil? || name.empty?)

      super(name: name, id: id, **filter)
    end
  end
end
