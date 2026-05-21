# frozen_string_literal: true

class Fog::Hyperv::Compute
  # rubocop:disable Metrics/ClassLength

  class NetworkAdapter < Fog::Hyperv::Model
    # rubocop:disable Layout/HashAlignment

    # Network adapter statuses
    # @note Defined by Microsoft.HyperV.PowerShell.VMNetworkAdapterOperationalStatus
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

    NIC_FALLBACK_MAC = '000000000000'

    # @!attribute [r] id
    #   @return [String] the GUID of this network adapter
    identity :id

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this network adapter is attached to
    attribute :computer_name
    # @!attribute [r] vm_id
    #   @return [String,nil] the GUID of the VM this network adapter is attached to
    attribute :vm_id
    # @!attribute [r] is_management_os
    #   @return [Boolean] if the network adapter is attached to the management OS
    attribute :is_management_os, type: :boolean

    # attribute :acl_list
    # @!attribute [r] connected
    #   @return [Boolean] if the network adapter is connected to the network
    #   @see connect
    #   @see disconnect
    attribute :connected, type: :boolean

    # @!attribute dynamic_mac_address_enabled
    #   @return [Boolean] if the network adapter is assigned a dynamic MAC address
    attribute :dynamic_mac_address_enabled, type: :boolean, default: true
    # @!attribute [r] ip_addresses
    #   @return [Array<String>] the IP addresses currently assigned to the network adapter
    attribute :ip_addresses
    # attribute :is_deleted
    # @!attribute [r] is_external_adapter
    #   @return [Boolean] if the network adapter is external to the VM
    attribute :is_external_adapter, type: :boolean
    # @!attribute [r] is_legacy
    #   @return [Boolean] if the network adapter is using legacy option ROM
    attribute :is_legacy, type: :boolean
    # @!attribute mac_address
    #   @return [String] the MAC address of the network adapter
    #   @note Can only be changed if dynamic_mac_address_enabled is false
    attribute :mac_address
    # @!attribute name
    #   @return [String] the name of the network adapter
    attribute :name
    # @!attribute mac_address_spoofing
    #   @return [:On, :Off] if the NIC should be allowed to send packets with different MAC address
    attribute :mac_address_spoofing, type: :hypervenum, values: Fog::Hyperv::ON_OFF_STATE_ENUM_VALUES
    # @!attribute dhcp_guard
    #   @return [:On, :Off] if the NIC should drop DHCP messages from unauthorized VMs
    attribute :dhcp_guard, type: :hypervenum, values: Fog::Hyperv::ON_OFF_STATE_ENUM_VALUES
    # @!attribute router_guard
    #   @return [:On, :Off] if the NIC should drop RA/Redirection messages from unauthorized VMs
    attribute :router_guard, type: :hypervenum, values: Fog::Hyperv::ON_OFF_STATE_ENUM_VALUES
    # @!attribute allow_teaming
    #   @return [:On, :Off] if the NIC should be allowed to be teamed with other NICs on the same switch
    attribute :allow_teaming, type: :hypervenum, values: Fog::Hyperv::ON_OFF_STATE_ENUM_VALUES
    # @!attribute [r] status
    #   @return [Symbol] the status of the network adapter
    #   @see NIC_STATUS_ENUM_VALUES
    attribute :status, type: :hypervenumarray, values: NIC_STATUS_ENUM_VALUES
    # @!attribute switch_id
    #   @return [String] the ID of the switch the adapter is connected to
    #   @see connect
    #   @see disconnect
    attribute :switch_id
    # @!attribute switch_name
    #   @return [String] the name of the switch the adapter is connected to
    #   @see connect
    #   @see disconnect
    attribute :switch_name

    has_one :vlan_setting, :vlan_setting

    # @!attribute [r] vlan_setting
    # @return [NetworkAdapterVlan] the VLAN that the network adapter is connected to
    def vlan_setting
      return associations[:vlan_setting] if associations[:vlan_setting]

      require_relative 'network_adapter_vlan'
      attrs = { parent_adapter: self, service: @service, vm: @vm }

      if persisted?
        requires :id
        requires :vm_id unless is_management_os

        associations[:vlan_setting] = Fog::Hyperv::Compute::NetworkAdapterVlan.new(
          **service.get_vm_network_adapter_vlan(
            computer_name:,
            management_os: is_management_os,
            vm_id:,
            id:,

            _return_fields: Fog::Hyperv::Compute::NetworkAdapterVlan.attributes
          ),
          **attrs
        )
      else
        associations[:vlan_setting] = Fog::Hyperv::Compute::NetworkAdapterVlan.new(attrs)
      end
    end

    # Connect the network adapter to a given switch
    # @param switch [Switch,String] a switch - or the ID/name of one - to connect to
    def connect(switch, **options)
      requires :id

      if switch.is_a? Fog::Hyperv::Compute::Switch
        new_switch_id = switch.id
        new_switch_name = switch.name
      else
        new_switch_id = switch if switch.is_a?(String) && switch =~ Fog::Hyperv::GUID
        new_switch_name = switch unless new_switch_id
      end
      options[:management_os] = true if is_management_os

      service.connect_vm_network_adapter(
        computer_name:,
        vm_id:,
        id:,

        switch_id: new_switch_id,
        switch_name: new_switch_name,

        **options
      )

      old.switch_id = attributes[:switch_id] = new_switch_id
      old.switch_name = attributes[:switch_name] = new_switch_name
      true
    end

    # Disconnect the network adapter from any connected switch
    def disconnect(**options)
      requires :id

      options[:management_os] = true if is_management_os
      service.disconnect_vm_network_adapter(
        computer_name:,
        vm_id:,
        id:,

        **options
      )

      old.switch_id = attributes[:switch_id] = nil
      old.switch_name = attributes[:switch_name] = nil
      true
    end

    # @!attribute switch
    # @return [Switch,nil] the switch the network adapter is connected to
    # @see connect
    # @see disconnect
    def switch
      service.switches.get(switch_id:, switch_name:, computer_name:) if switch_name.any? || switch_id.any?
    end

    def switch=(new_switch)
      if new_switch.nil?
        attributes[:switch_id] = nil
        attributes[:switch_name] = nil

        return
      end

      raise 'Not a switch' unless new_switch.is_a? Fog::Hyperv::Compute::Switch

      attributes[:switch_id] = new_switch.id
      attributes[:switch_name] = new_switch.name
    end

    def create
      selector = {}
      if is_management_os
        selector[:management_os] = true
      else
        requires :vm_id

        selector[:vm_id] = vm_id
      end

      args = { name:, switch_name: }
      args[:is_legacy] = true if is_legacy
      if !dynamic_mac_address_enabled && mac_address != NIC_FALLBACK_MAC
        args[:static_mac_address] = mac_address
      else
        args[:dynamic_mac_address] = true
      end
      data = service.add_vm_network_adapter(
        **selector,
        computer_name:,

        **args,

        _return_fields: self.class.attributes
      )
      post_save_changes = {
        mac_address_spoofing: mac_address_spoofing,
        dhcp_guard: dhcp_guard,
        router_guard: router_guard,
        allow_teaming: allow_teaming
      }.compact

      merge_attributes(data)
      vlan_setting.save if associations[:vlan_setting]
      return self unless post_save_changes.any?

      attributes.merge!(post_save_changes)
      update if dirty?

      self
    end

    def update
      requires :id
      requires :vm_id unless is_management_os

      data = {}
      if changed?(:name)
        service.rename_vm_network_adapter(
          computer_name: old.computer_name,
          id: old.id,
          vm_id: old.vm_id,
          management_os: old.is_management_os,

          new_name: name
        )
        data[:name] = name
      end

      changes = build_changelist
      if changes.any?
        data.merge!(
          service.set_vm_network_adapter(
            computer_name: old.computer_name,
            id: old.id,
            vm_id: old.vm_id,
            management_os: old.is_management_os,

            **changes,

            _always_include: changes.keys,
            _return_fields: self.class.attributes
          )
        )
      end

      if changed?(:switch_name) || changed?(:switch_id)
        save_switch
        data[:switch_name] = switch_name
        data[:switch_id] = switch_id
      end
      vlan_setting.save if associations[:vlan_setting] && vlan_setting.dirty?

      merge_attributes(data)
    end

    def destroy
      requires :id
      requires :vm_id unless is_management_os

      service.remove_vm_network_adapter(
        computer_name:,
        vm_id:,
        id:,
        management_os: is_management_os
      )
      true
    end

    def reload
      requires :id
      requires :vm_id unless is_management_os

      data = service.get_vm_network_adapter(
        computer_name:,
        vm_id:,
        id:,
        management_os: is_management_os,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end

    protected

    def merge_attributes(new_attributes = {})
      new_attributes[:ip_addresses] = [] if new_attributes[:ip_addresses] == ''
      new_attributes[:mac_address] = NIC_FALLBACK_MAC if new_attributes[:mac_address].nil? || new_attributes[:mac_address] == ''

      super
    end

    private

    def build_changelist
      changes = {
        mac_address_spoofing: changed!(:mac_address_spoofing),
        dhcp_guard: changed!(:dhcp_guard),
        router_guard: changed!(:router_guard),
        allow_teaming: changed!(:allow_teaming)
      }.compact
      unless is_management_os
        if dynamic_mac_address_enabled
          changes[:dynamic_mac_address] = changed!(:dynamic_mac_address_enabled)
        elsif mac_address && mac_address != NIC_FALLBACK_MAC
          changes[:static_mac_address] = changed!(:mac_address)
          changes[:static_mac_address] ||= changed?(:dynamic_mac_address_enabled) ? mac_address : nil
        end
      end
      changes.compact
    end

    def save_switch
      selector = { computer_name:, vm_id:, id: }.compact
      selector[:management_os] = true if is_management_os

      if switch_name || switch_id
        service.connect_vm_network_adapter(**selector, switch_name:, switch_id:)
      else
        service.disconnect_vm_network_adapter(**selector)
      end
    end
  end
  # rubocop:enable Metrics/ClassLength
end
