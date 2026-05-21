# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Switch < Fog::Hyperv::Model
    # @!attribute [r] id
    #   @return [String] the GUID of the network switch
    identity :id

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer hosting this network switch
    attribute :computer_name

    # @!attribute allow_management_os
    #   @return [Boolean] is the management OS allowed to use this switch
    attribute :allow_management_os, type: :boolean
    # @!attribute default_flow_minimum_bandwidth_absolute
    #   @return [Integer] the default minimum bandwidth allocation for VMs without specific allocations
    attribute :default_flow_minimum_bandwidth_absolute, type: :integer
    # @!attribute default_flow_minimum_bandwidth_weight
    #   @return [Integer] the default minimum bandwidth allocation for VMs without specific allocations, as a relative weight
    attribute :default_flow_minimum_bandwidth_weight, type: :integer
    # @!attribute name
    #   @return [String] the name of the network switch
    attribute :name
    # @!attribute [r] net_adapter_interface_description
    #   @return [String] the network interface description this switch is attached to
    attribute :net_adapter_interface_description
    # @!attribute [r] net_adapter_name
    #   @return [String] the network interface name this switch is attached to
    attribute :net_adapter_name
    # @!attribute notes
    #   @return [String] the user-specified notes for the network switch
    attribute :notes
    # @!attribute resource_pool_name
    #   @return [String] the resource pool the switch is part of
    attribute :resource_pool_name
    # @!attribute [r] switch_type
    #   @return [:Private, :Internal, :External] the type of network switch
    attribute :switch_type, type: :hypervenum, values: %i[Private Internal External]

    def create
      requires :name
      requires_one :net_adapter_name, :net_adapter_interface_description, :switch_type

      merge_attributes(
        service.new_vm_switch(
          computer_name:,
          name:,

          allow_management_os:,
          net_adapter_interface_description:,
          net_adapter_name:,
          notes:,
          switch_type: !net_adapter_interface_description && switch_type,

          _return_fields: self.class.attributes
        )
      )
    end

    def update
      requires :id

      if changed?(:name)
        service.rename_vm_switch(
          computer_name: old.computer_name,
          id: old.id,

          new_name: name
        )
        @old.name = name
      end

      changes = {
        allow_management_os: changed!(:allow_management_os),
        default_flow_minimum_bandwidth_absolute: changed!(:default_flow_minimum_bandwidth_absolute),
        default_flow_minimum_bandwidth_weight: changed!(:default_flow_minimum_bandwidth_weight),
      }.compact
      changes[:notes] = notes || '' if changed? :notes
      return self unless changes.any?

      merge_attributes(
        service.set_vm_switch(
          computer_name: old.computer_name,
          id: old.id,

          **changes,

          _always_include: changes.keys,
          _return_fields: self.class.attributes
        )
      )
    end

    def destroy
      requires :id

      service.remove_vm_switch(
        computer_name:,
        id:
      )
      true
    end

    def reload
      requires :id

      data = service.get_vm_switch(
        computer_name:,
        id:
      )
      return unless data

      merge_attributes(data)
    end
  end
end
