require 'fog/core/collection'

module Fog
  module Hyperv
    class Collection < Fog::Collection
      def self.get_method(method = nil)
        @get_method ||= method
      end

      def self.requires
        @requires ||= []
      end

      def self.requires?(req)
        requires.include? req
      end

      def search_attributes
        attributes.dup.merge(
          _return_fields: model.attributes - model.lazy_attributes,
          _json_depth: 1
        )
      end

      def all(filters = {})
        requires(*self.class.requires)
        data = service.send(method, search_attributes.merge(filters))
        data = [] unless data

        load [data].flatten
      end

      def get(filters = {})
        data = all(filters).first
        data if data
      rescue Fog::Hyperv::Errors::PSError => err
        raise Fog::Errors::NotFound, err if err.message =~ /Hyper-V was unable to find|^No .* is found|/
        raise err
      end

      def new(options = {})
        requires(*self.class.requires)
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
      def self.requires_computer
        requires << :computer
      end

      attr_accessor :cluster
      attr_accessor :computer

      def search_attributes
        attrs = super
        attrs.delete :cluster
        attrs.delete :computer
        attrs[:computer_name] ||= cluster.hosts.map { |n| n.name } if cluster
        attrs[:computer_name] ||= computer.name if computer
        attrs
      end
    end

    class VMCollection < Fog::Hyperv::ComputerCollection
      def self.match_on(attr = nil)
        @match_on ||= attr
      end

      def self.requires_vm
        requires << :vm
      end

      attr_accessor :vm

      def search_attributes
        attrs = super
        attrs.delete :vm
        if vm
          attrs[:computer_name] ||= vm.computer_name
          attrs[match] = vm.send(match)
        end
        attrs
      end

      def create(attributes = {})
        object = new(attributes)
        # Ensure both ID and Name are populated, regardless of `match_on`
        object.vm_id ||= vm.id if vm && object.respond_to?(:vm_id)
        object.vm_name ||= vm.name if vm && object.respond_to?(:vm_name)
        object.save
        object
      end

      def inspect
        # To avoid recursing on VM
        to_s
      end

      private

      def logger
        service.logger
      end

      def match
        self.class.match_on || :vm_name
      end
    end
  end
end
