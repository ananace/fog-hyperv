# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class NetworkAdapterVlan < Fog::Hyperv::Model
        # @!attribute [r] vm_network_adapter_name
        #   @return [String] the name of the network adapter this VLAN configuration is attached to
        identity :vm_network_adapter_name

        # @!attribute [r] computer_name
        #   @return [String] the name of the computer running the VM that this VLAN configuration is attached to
        attribute :computer_name
        # @!attribute [r] vm_name
        #   @return [String] the name of the VM this VLAN configuration is attached to
        attribute :vm_name

        # @!attribute operation_mode
        #   @return [:Untagged, :Access, :Trun, :Isolated, :Promiscuous] the active VLAN mode
        attribute :operation_mode, type: :enum, default: :Untagged, values: %i[
          Untagged Access Trunk Isolated Promiscuous
        ]
        # @!attribute access_vlan_id
        #   @return [Integer] the VLAN ID to use for operation_mode +:Access+
        attribute :access_vlan_id, type: :integer
        # @!attribute allowed_vlan_id_list
        #   @return [Array<Integer>] the list of allowed VLAN IDs to use for operation_mode +:Trunk+
        attribute :allowed_vlan_id_list
        # @!attribute native_vlan_id
        #   @return [Integer] the native VLAN ID to use for operation_mode +:Trunk+
        attribute :native_vlan_id, type: :integer
        # @!attribute primary_vlan_id
        #   @return [Integer] the primary VLAN ID to use for operation_mode +:Isolated+ or +:Promiscuous+
        attribute :primary_vlan_id, type: :integer
        # @!attribute secondary_vlan_id
        #   @return [Integer] the secondary VLAN ID to use for operation_mode +:Isolated+
        attribute :secondary_vlan_id, type: :integer
        # @!attribute secondary_vlan_id_list
        #   @return [Array<Integer>] the list of secondary VLAN IDs to use for operation_mode +:Promiscuous+
        attribute :secondary_vlan_id_list

        def initialize(**attributes)
          parent = attributes.delete :parent_adapter
          if parent.is_a? Fog::Hyperv::Compute::NetworkAdapter
            @interface = parent
            attributes[:vm_network_adapter_name] = parent.name
            attributes[:vm_name] = parent.vm_name
          else
            attributes[:vm_network_adapter_name] = parent[:name]
            attributes[:vm_name] = parent[:vm_name]
          end

          super
        end

        # @!attribute [r] network_adapter
        # @return [NetworkAdapter] the network adapter this VLAN configuration is attached to
        def network_adapter
          service.network_adapters.get vm_network_adapter_name, vm_name: vm_name
        end

        def save
          requires :computer_name, :vm_name, :vm_network_adapter_name
          return unless persisted? # Can't happen

          args = {
            computer_name: old.computer_name,
            vm_name: old.vm_name,
            vm_network_adapter_name: old.vm_network_adapter_name
          }
          case operation_mode
          when :Untagged
            args[:untagged] = true
          when :Access
            requires :access_vlan_id
            args[:access] = true
            args[:access_vlan_id] = access_vlan_id
          when :Trunk
            requires :allowed_vlan_id_list, :native_vlan_id
            args[:trunk] = true
            args[:allowed_vlan_id_list] = allowed_vlan_id_list
            args[:native_vlan_id] = native_vlan_id
          when :Isolated
            requires :primary_vlan_id, :secondary_vlan_id
            args[:isolated] = true
            args[:primary_vlan_id] = primary_vlan_id
            args[:secondary_vlan_id] = secondary_vlan_id
          when :Promiscuous
            requires :primary_vlan_id, :secondary_vlan_id_list
            args[:promiscuous] = true
            args[:primary_vlan_id] = primary_vlan_id
            args[:secondary_vlan_id_list] = secondary_vlan_id_list
          end

          service.set_vm_network_adapter_vlan(args)
          reload
        end

        def reload
          data = self.class.new service.get_vm_network_adapter_vlan(
            computer_name: computer_name,
            vm_name: vm_name,
            vm_network_adapter_name: vm_network_adapter_name,

            _return_fields: self.class.attributes + %i[parent_adapter]
          )

          merge_attributes(data.attributes)
          @old = data
          self
        end
      end
    end
  end
end
