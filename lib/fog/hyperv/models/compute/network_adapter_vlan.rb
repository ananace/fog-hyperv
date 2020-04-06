# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class NetworkAdapterVlan < Fog::Hyperv::Model
        identity :vm_network_adapter_name

        attribute :computer_name
        attribute :operation_mode, type: :enum, default: :Untagged, values: %i[
          Untagged Access Trunk Isolated Promiscuous
        ]
        attribute :access_vlan_id
        attribute :allowed_vlan_id_list
        attribute :native_vlan_id
        attribute :primary_vlan_id
        attribute :secondary_vlan_id
        attribute :secondary_vlan_id_list
        attribute :vm_name

        def initialize(**attributes)
          parent = attributes.delete :parent_adapter
          if parent.is_a? Fog::Compute::Hyperv::NetworkAdapter
            @interface = parent
            attributes[:vm_network_adapter_name] = parent.name
            attributes[:vm_name] = parent.vm_name
          else
            attributes[:vm_network_adapter_name] = parent[:name]
            attributes[:vm_name] = parent[:vm_name]
          end

          super
        end

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
          if operation_mode == :Untagged
            args[:untagged] = true
          elsif operation_mode == :Access
            requires :access_vlan_id
            args[:access] = true
            args[:access_vlan_id] = access_vlan_id
          elsif operation_mode == :Trunk
            requires :allowed_vlan_id_list, :native_vlan_id
            args[:trunk] = true
            args[:allowed_vlan_id_list] = allowed_vlan_id_list
            args[:native_vlan_id] = native_vlan_id
          elsif operation_mode == :Isolated
            requires :primary_vlan_id, :secondary_vlan_id
            args[:isolated] = true
            args[:primary_vlan_id] = primary_vlan_id
            args[:secondary_vlan_id] = secondary_vlan_id
          elsif operation_mode == :Promiscuous
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
