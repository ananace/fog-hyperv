# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class NetworkAdapter < Fog::Hyperv::Model
        # rubocop:disable Layout/HashAlignment

        # Network adapter statuses
        NIC_STATUS_ENUM_VALUES = {
          Unknown:             0,
          Other:               1,
          Ok:                  2,
          Degraded:            3,
          Stressed:            4,
          PredictiveFailure:   5,
          Error:               6,
          NonRecoverableError: 7,
          Starting:            8,
          Stopping:            9,
          Stopped:             10,
          InService:           11,
          NoContact:           12,
          LostCommunication:   13,
          Aborted:             14,
          Dormant:             15,
          SupportingEntity:    16,
          Completed:           17,
          PowerMode:           18,
          ProtocolVersion:     32_775
        }.freeze
        # rubocop:enable Layout/HashAlignment

        # @!attribute [r] id
        #   @return [String] the GUID of this network adapter
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] the name of the computer running the VM that this network adapter is attached to
        attribute :computer_name
        # @!attribute [r] vm_id
        #   @return [String] the GUID of the VM this network adapter is attached to
        attribute :vm_id
        # @!attribute [r] vm_name
        #   @return [String] the name of the VM this network adapter is attached to
        attribute :vm_name

        # attribute :acl_list
        # @!attribute [r] connected
        #   @return [Boolean] is the network adapter connected to the network
        #   @see connect
        #   @see disconnect
        attribute :connected, type: :boolean

        # @!attribute dynamic_mac_address_enabled
        #   @return [Boolean] is the network adapter assigned a dynamic MAC address
        attribute :dynamic_mac_address_enabled, type: :boolean, default: true
        # @!attribute [r] ip_addresses
        #   @return [Array<String>] the IP addresses currently assigned to the network adapter
        attribute :ip_addresses
        # attribute :is_deleted
        # @!attribute [r] is_external_adapter
        #   @return [Boolean] is the network adapter external to the VM
        attribute :is_external_adapter, type: :boolean
        # @!attribute [r] is_legacy
        #   @return [Boolean] is the network adapter using legacy ROM
        attribute :is_legacy, type: :boolean
        # @!attribute [r] is_management_os
        #   @return [Boolean] is the network adapter attached to the management OS
        attribute :is_management_os, type: :boolean
        # attribute :isolation_setting # Might need lazy loading
        # @!attribute mac_address
        #   @return [String] the MAC address of the network adapter
        #   @note Can only be changed if dynamic_mac_address_enabled is false
        attribute :mac_address
        # @!attribute [r] name
        #   @return [String] the name of the network adapter
        attribute :name, type: :string, default: 'Network Adapter'
        # attribute :router_guard, type: :enum, values: [ :On, :Off ]
        # attribute :status, type: :enum, values: STATUS_ENUM_VALUES
        # @!attribute [r] switch_id
        #   @return [String] the ID of the switch the adapter is connected to
        #   @see connect
        #   @see disconnect
        attribute :switch_id
        # @!attribute [r] switch_name
        #   @return [String] the name of the switch the adapter is connected to
        #   @see connect
        #   @see disconnect
        attribute :switch_name, type: :string

        lazy_attributes :vlan_setting

        # @!attribute [r] vlan_setting
        # @return [NetworkAdapterVlan] the VLAN that the network adapter is connected to
        def vlan_setting
          attributes[:vlan_setting] ||= Fog::Hyperv::Compute::NetworkAdapterVlan.new(
            (
              if persisted?
                service.get_vm_network_adapter_vlan(
                  computer_name: computer_name,
                  vm_name: vm_name,
                  vm_network_adapter_name: name,

                  _return_fields: Fog::Hyperv::Compute::NetworkAdapterVlan.attributes + %i[parent_adapter]
                )
              else
                {
                  computer_name: computer_name,
                  parent_adapter: {
                    computer_name: computer_name,
                    vm_name: vm_name,
                    name: name
                  }
                }
              end
            ).merge(
              parent_adapter: self,
              service: service
            )
          )
        end

        # Connect the network adapter to a given switch
        # @param switch [Switch,String] a switch - or the name of one - to connect to
        def connect(switch, **options)
          requires :name, :computer_name, :vm_name

          switch = switch.name if switch.is_a? Fog::Hyperv::Compute::Switch

          service.connect_vm_network_adapter options.merge(
            computer_name: computer_name,
            name: name,
            switch_name: switch,
            vm_name: vm_name
          )
        end

        # Disconnect the network adapter from any connected switch
        def disconnect(**options)
          requires :name, :computer_name, :vm_name

          service.disconnect_vm_network_adapter options.merge(
            computer_name: computer_name,
            name: name,
            vm_name: vm_name
          )
        end

        # @!attribute [r] switch
        # @return [Switch] the switch the network adapter is connected to
        # @see connect
        # @see disconnect
        def switch
          service.switches.get switch_name, computer_name: computer_name if switch_name
        end

        def save
          requires :name, :computer_name, :vm_name

          data =
            if persisted?
              ret = service.set_vm_network_adapter(
                computer_name: old.computer_name,
                name: old.name,
                vm_name: old.vm_name,
                passthru: true,

                dynamic_mac_address: changed?(:dynamic_mac_address_enabled) && dynamic_mac_address_enabled,
                static_mac_address: changed!(:mac_address) || ((changed!(:dynamic_mac_address_enabled) == false) && mac_address),

                _return_fields: self.class.attributes,
                _json_depth: 1
              )

              save_switch if changed?(:switch_name)
              ret[:switch_name] = switch_name
              ret
            else
              service.add_vm_network_adapter(
                computer_name: computer_name,
                name: name,
                vm_name: vm_name,
                passthru: true,

                dynamic_mac_address: dynamic_mac_address_enabled,
                is_legacy: !!is_legacy, # rubocop:disable Style/DoubleNegation -- Bool ensurance
                static_mac_address: !dynamic_mac_address_enabled && mac_address,
                switch_name: switch_name,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            end

          vlan_setting.save if attributes[:vlan_setting] && (!persisted? || vlan_setting.dirty?)

          if data.is_a? Array
            data = data.find { |e| e[:id] == id } if id
            data = data.last unless id
          end

          merge_attributes(data)
          @old = dup
          self
        end

        def destroy
          requires :vm_name, :name, :computer_name, :id

          service.remove_vm_network_adapter(
            name: name,
            computer_name: computer_name,
            vm_name: vm_name
          )
        end

        def reload
          data = collection.get(
            name,
            computer_name: computer_name,
            vm_name: vm_name,
            _suffix: "| Where Id -Eq '#{id}'"
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end

        protected

        def merge_attributes(new_attributes = {})
          new_attributes[:ip_addresses] = [] if new_attributes[:ip_addresses] == ''

          super
        end

        private

        def save_switch
          if switch_name
            service.connect_vm_network_adapter(
              computer_name: ret.computer_name,
              name: ret.name,
              vm_name: ret.vm_name,
              switch_name: switch_name
            )
          else
            service.disconnect_vm_network_adapter(
              computer_name: ret.computer_name,
              name: ret.name,
              vm_name: ret.vm_name
            )
          end
        end
      end
    end
  end
end
