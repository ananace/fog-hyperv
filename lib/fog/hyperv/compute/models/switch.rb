# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class Switch < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] the GUID of the network switch
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] the name of the computer hosting this network switch
        attribute :computer_name

        # attribute :default_flow_minimum_bandwidth_absolute
        # attribute :default_flow_minimum_bandwidth_weight
        # attribute :is_deleted
        # @!attribute [r] name
        #   @return [String] the name of the network switch
        attribute :name
        # @!attribute [r] net_adapter_interface_description
        #   @return [String] the network interface description this switch is attached to
        attribute :net_adapter_interface_description
        # @!attribute notes
        #   @return [String] the user-specified notes for the network switch
        attribute :notes
        # @!attribute [r] switch_type
        #   @return [:Private, :Internal, :External] the type of network switch
        attribute :switch_type, type: :enum, values: %i[Private Internal External]

        def save
          requires :name

          data =
            if persisted?
              service.set_vm_switch(
                computer_name: old.computer_name,
                name: old.name,
                net_adapter_interface_description: old.net_adapter_interface_description,
                switch_type: !old.net_adapter_interface_description && old.switch_type,
                passthru: true,

                default_flow_minimum_bandwidth_absolute: changed!(default_flow_minimum_bandwidth_absolute),
                default_flow_minimum_bandwidth_weight: changed!(default_flow_minimum_bandwidth_weight),
                notes: changed!(notes),

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            else
              service.new_vm_switch(
                computer_name: computer_name,
                name: name,
                net_adapter_interface_description: net_adapter_interface_description,
                notes: notes,
                switch_type: !net_adapter_interface_description && switch_type,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            end

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          data = collection.get(
            name,
            computer_name: computer_name
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end
      end
    end
  end
end
