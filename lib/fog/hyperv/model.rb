# frozen_string_literal: true

module Fog::Hyperv
  module ModelExtends
    # Attach a collection of sub-models
    # @param name [Symbol] the attribute name to store the collection under
    # @param collection_name [Symbol] the name of the collection on the service
    # @param options [Hash] the options to create the collection attachment with
    # @see Fog::Hyperv::Associations::Collection
    def collection(name, collection_name = nil, options = {}) # rubocop:disable Style/OptionHash -- upstream design
      collection_name ||= name
      Fog::Hyperv::Associations::Collection.new(self, name, collection_name, options)

      case to_s
      when 'Fog::Hyperv::Compute::Server'
        define_method name do
          associations[name] ||= service.send(collection_name, vm: self, computer_name: computer_name, vm_id: id)
        end
      when 'Fog::Hyperv::Compute::Host'
        define_method name do
          associations[name] ||= service.send(collection_name, computer: self, computer_name: computer_name)
        end
      else
        raise "Unknown class #{self}"
      end

      define_method :"#{name}=" do |data|
        assoc = associations[name] || send(name)
        assoc.clear
        assoc.instance_variable_set :@loaded, true
        [data].flatten.each do |obj|
          obj = assoc.new obj if obj.is_a?(Hash)
          assoc << obj
        end
        assoc
      end
    end
  end

  module ModelIncludes
    # Has the model been modified
    # @return [Boolean] have any attributes changed since the model was retrieved
    def dirty?
      dirty.any?
    end

    # Get all dirty attributes
    # @return [Array<Symbol>] all the attributes that have changed since the model was retrieved
    def dirty
      potential = attributes.slice(*self.class.attributes)
      return potential unless old

      potential.reject { |k, v| old.attributes[k] == v }.keys
    end

    # Get the VM this model is attached to
    # @return [Fog::Hyperv::Compute::Server,nil] the VM this model is attached to, if any
    def vm
      return @vm if @vm
      return unless respond_to?(:vm_id) && vm_id

      @vm ||= service.servers.get vm_id
    end

    # Get the Computer this model is attached to
    # @return [Fog::Hyperv::Compute::Host,nil] the Computer this model is attached to, if any
    def computer
      return @computer if @computer
      return @computer ||= service.hosts.get(computer_name) if respond_to?(:computer_name) && computer_name

      @computer ||= vm&.computer
    end

    # Get the Cluster this model is part of
    # @return [Fog::Hyperv::Compute::Cluster,nil] the Cluster this model is part of, if any
    def cluster
      return @cluster if @cluster
      return unless respond_to?(:cluster_name) && cluster_name

      @cluster ||= service.clusters.get cluster_name
    end

    private

    def logger
      service.logger
    end

    # Has any of the listed attributes been modified
    # @param attrs [Symbol] the attributes to check for modification
    # @param all [Boolean] check if all listed attributes have changed, instead of any
    # @return [Boolean] are any/all of the listed attributes modified
    def changed?(*attrs, all: false)
      return false unless old

      changed = dirty
      if all
        attrs.all? { |attr| changed.include? attr }
      else
        attrs.any? { |attr| changed.include? attr }
      end
    end

    # Return the modified value of the given attribute - if any
    # @return [Object,nil] the modified value of the attribute, or nil if it's unmodified
    def changed!(attr)
      changed?(attr) ? attributes[attr] : nil
    end

    # Return the old values of the model - i.e. what's stored in Hyper-V
    # @return [Object,nil] the old copy of the model, or nil if there's no older version available
    def old
      @old ||= (persisted? ? dup.reload : nil)
    end
  end

  # A slightly specialized Fog::Model which includes shared Hyper-V functionality
  class Model < Fog::Model
    extend Fog::Hyperv::ModelExtends
    include Fog::Hyperv::ModelIncludes

    def initialize(attributes = {})
      @vm = attributes.delete :vm
      self.attributes[:vm] = @vm if self.class.attributes.include? :vm
      @computer = attributes.delete :computer
      self.attributes[:computer] = @computer if self.class.attributes.include? :computer
      @cluster = attributes.delete :cluster
      self.attributes[:cluster] = @cluster if self.class.attributes.include? :cluster

      super

      @old = dup if persisted?
    end

    def merge_attributes(attributes = {})
      super

      @old = dup
      self
    end
  end
end
