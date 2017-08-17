require 'fog/core/collection'

module Fog
  module Hyperv
    class Collection < Fog::Collection
      def self.get_method(method = nil)
        @get_method ||= method
      end

      def search_attributes
        attributes.dup.merge(
          _return_fields: model.attributes - model.lazy_attributes,
          _json_depth: 1
        )
      end

      def all(filters = {})
        data = service.send(method, search_attributes.merge(filters))
        data = [] unless data

        load [data].flatten
      end

      def get(filters = {})
        data = service.send(method, search_attributes.merge(filters))

        new data if data
      end

      def new(options = {})
        super(search_attributes.merge(options))
      end

      def create(attributes = {})
        object = new(attributes)
        object.save
        object
      end

      private

      def method
        self.class.get_method
      end
    end

    class ComputerCollection < Fog::Hyperv::Collection
      def self.inherited(subclass)
        subclass.attribute :computer
        super
      end

      def search_attributes
        attrs = super
        attrs[:computer_name] ||= attrs.delete(:computer).name if attrs[:computer]
        attrs
      end
    end

    class VMCollection < Fog::Hyperv::ComputerCollection
      def self.match_on(attr = nil)
        @match_on ||= attr
      end

      def self.inherited(subclass)
        subclass.attribute :vm
        super
      end

      def search_attributes
        attrs = super
        vm = attrs.delete(:vm)
        if vm
          attrs[:computer_name] ||= vm.computer_name
          attrs[match] = vm.send(match)
        end
        attrs
      end

      def create(attributes = {})
        object = new(attributes)
        # Ensure both ID and Name are populated, regardless of `match_on`
        object.vm_id = vm.id if vm && object.respond_to?(:vm_id)
        object.vm_name = vm.name if vm && object.respond_to?(:vm_id)
        object.save
        object
      end

      def inspect
        # To avoid recursing on VM
        to_s
      end

      private

      def match
        self.class.match_on || :vm_name
      end
    end
  end
end
