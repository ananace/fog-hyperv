require 'fog/core/collection'

module Fog
  module Hyperv
    class Collection < Fog::Collection
      attribute :computer_name

      def self.get_method(method = nil)
        @get_method ||= method
      end

      def all(filters = {})
        load [service.send(self.class.get_method, attributes.merge(
          _return_fields: model.attributes - model.lazy_attributes,
          _json_depth: 1
        ).merge(filters))].flatten
      end

      def get(filters = {})
        result = service.send(self.class.get_method, attributes.merge(
          _return_fields: model.attributes - model.lazy_attributes,
          _json_depth: 1
        ).merge(filters))
        new result if result
      end

      def new(options = {})
        super(attributes.merge(options))
      end
    end

    class VMCollection < Fog::Hyperv::Collection
      attribute :vm_name
    end
  end
end
