# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Vhds < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Vhd

    get_method :get_vhd

    attribute :computer_name

    def get(identifier, **filters)
      id = identifier if identifier =~ /\A#{Fog::Hyperv::GUID}\z/i
      path = identifier unless id

      raise ArgumentError, 'Must provide a path or GUID' if (id.nil? || id.empty?) && (path.nil? || path.empty?)

      super(disk_identifier: id, path: path, **filters)
    end

    protected

    def search_attributes
      super.merge(
        _return_fields: model.attributes - %i[basename]
      )
    end
  end
end
