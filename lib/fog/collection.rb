require 'fog/core/collection'

module Fog
  module Hyperv
    class Collection < Fog::Collection
      attribute :computer_name

      def self.get_method(method = nil)
        @get_method ||= method
      end

      def all(filters = {})
        attrs = attributes
        if attributes[:vm]
          attrs[:vm_name] = vm.name
          attrs[:computer_name] ||= vm.computer_name
          attrs.delete :vm
        end
        load [service.send(self.class.get_method, attrs.merge(
          _return_fields: model.attributes - model.lazy_attributes,
          _json_depth: 1
        ).merge(filters))].flatten
      end

      def get(filters = {})
        attrs = attributes
        if attributes[:vm]
          attrs[:vm_name] = vm.name
          attrs[:computer_name] ||= vm.computer_name
          attrs.delete :vm
        end
        new service.send(self.class.get_method, attrs.merge(
          _return_fields: model.attributes - model.lazy_attributes,
          _json_depth: 1
        ).merge(filters))
      end

      def new(options = {})
        super(attributes.merge(options))
      end

      def create(attributes = {})
        object = new(attributes)
        object.save
        object
      end
    end

    class VMCollection < Fog::Hyperv::Collection
      attribute :vm
    end
  end
end
