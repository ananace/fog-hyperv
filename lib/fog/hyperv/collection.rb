# frozen_string_literal: true

module Fog::Hyperv
  # Expanded Fog::Collection with Hyper-V specific configuration
  class Collection < Fog::Collection
    # Define the service request that is used to retrieve data for this collection
    def self.get_method(method = nil)
      @get_method ||= method
    end

    # Add required attributes for retrieving data for this collection
    def self.requires(*attr)
      @requires ||= []
      @requires += attr if attr.any?
      @requires
    end

    # Check if the collection requires a specific attribute
    def self.requires?(req)
      requires.include? req
    end

    def initialize(attributes = {})
      @vm = attributes.delete(:vm)
      @computer = attributes.delete(:computer)
      @network_adapter = attributes.delete(:network_adapter)
      @cluster = attributes.delete(:cluster)

      super
    end

    # Retrieve all instances for the collection
    def all(filters = {})
      requires(*self.class.requires)

      data = service.send(method, **search_attributes, **filters)
      data ||= []
      # Hyper-V will either return an array or a single value depending on the number of entries found
      data = [data].flatten

      return self.clone.load(data) if filters.any?

      load data
      @loaded = true
      self
    end

    # Get a specific instance in the collection
    def get(**filters)
      new [service.send(method, **search_attributes, **filters)].flatten.first
    rescue Fog::Hyperv::Errors::PSError => e
      raise Fog::Errors::NotFound, e if e.message =~ /Hyper-V was unable to find|^No .* is found/

      raise
    end

    # Create a new instance in the collection
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
        {
          vm: @vm,
          computer: @computer,
          network_adapter: @network_adapter,
          cluster: @cluster
        }.compact
      )
    end

    private

    def method
      self.class.get_method
    end
  end
end
