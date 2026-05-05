# frozen_string_literal: true

module Fog::Hyperv
  class Collection < Fog::Collection
    def self.get_method(method = nil)
      @get_method ||= method
    end

    def self.requires(*attr)
      @requires ||= []
      @requires += attr if attr.any?
      @requires
    end

    def self.requires?(req)
      requires.include? req
    end

    def initialize(attributes = {})
      @vm = attributes.delete(:vm)
      @computer = attributes.delete(:computer)
      @network_adapter = attributes.delete(:network_adapter)

      super
    end

    def all(filters = {})
      requires(*self.class.requires)

      data = service.send(method, **search_attributes, **filters)
      data ||= []

      load [data].flatten
    end

    def get(**filters)
      all(filters).first
    rescue Fog::Hyperv::Errors::PSError => e
      raise Fog::Errors::NotFound, e if e.message =~ /Hyper-V was unable to find|^No .* is found/

      raise
    end

    def new(attributes = {})
      requires(*self.class.requires)

      attributes = attributes.attributes if attributes.is_a? Fog::Model
      super(creation_attributes.merge(attributes))
    end

    protected

    def search_attributes
      attributes.merge(
        _return_fields: model.attributes
      )
    end

    def creation_attributes
      attributes.merge(
        vm: @vm,
        computer: @computer,
        network_adapter: @network_adapter
      )
    end

    private

    def method
      self.class.get_method
    end
  end
end
