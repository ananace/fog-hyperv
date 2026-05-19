# frozen_string_literal: true

class Fog::Hyperv::Compute
  class NetworkAdapterVlan < Fog::Hyperv::Model
    # VLAN mode
    # @note Defined by Microsoft.HyperV.PowerShell.VMNetworkAdapterVlanMode
    VLAN_OPERATION_MODE = %i[
      Untagged Access Trunk Private
    ].freeze

    # Extended mode for Private VLANs
    # @note Defined by Microsoft.HyperV.PowerShell.VMNetworkAdapterPrivateVlanMode
    PRIVATE_VLAN_MODE = %i[
      Unknown Isolated Community Promiscuous
    ].freeze

    # @!attribute operation_mode
    #   @return [:Untagged, :Access, :Trunk, :Private] the active VLAN mode
    attribute :operation_mode, type: :hypervenum, default: :Untagged, values: VLAN_OPERATION_MODE
    # @!attribute private_vlan_mode
    #   @return [:Isolated, :Community, :Promiscuous] the type of private VLAN mode to use
    attribute :private_vlan_mode, type: :hypervenum, default: :Isolated, values: PRIVATE_VLAN_MODE
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
    #   @return [Integer] the primary VLAN ID to use for operation_mode +:Private+
    attribute :primary_vlan_id, type: :integer
    # @!attribute secondary_vlan_id
    #   @return [Integer] the secondary VLAN ID to use for private_vlan_mode +:Isolated+ or +:Community+
    attribute :secondary_vlan_id, type: :integer
    # @!attribute secondary_vlan_id_list
    #   @return [Array<Integer>] the list of secondary VLAN IDs to use for private_vlan_mode +:Promiscuous+
    attribute :secondary_vlan_id_list

    # rubocop:disable Metrics/MethodLength -- Argument handling takes some space

    # @!attribute parent_adapter
    #   @return [NetworkAdapter] the network adapter this VLAN configuration applies to
    has_one :parent_adapter, :network_adapters

    alias identity :parent_adapter

    def update
      requires :parent_adapter

      args = {}
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
        args[:allowed_vlan_id_list] = allowed_vlan_id_list.join ','
        args[:native_vlan_id] = native_vlan_id
      when :Private
        requires :private_vlan_mode, :primary_vlan_id
        case private_vlan_mode
        when :Isolated
          requires :secondary_vlan_id
          args[:isolated] = true
          args[:primary_vlan_id] = primary_vlan_id
          args[:secondary_vlan_id] = secondary_vlan_id
        when :Community
          requires :secondary_vlan_id
          args[:community] = true
          args[:primary_vlan_id] = primary_vlan_id
          args[:secondary_vlan_id] = secondary_vlan_id
        when :Promiscuous
          requires :secondary_vlan_id_list
          args[:promiscuous] = true
          args[:primary_vlan_id] = primary_vlan_id
          args[:secondary_vlan_id_list] = secondary_vlan_id_list.join ','
        end
      end

      merge_attributes(
        service.set_vm_network_adapter_vlan(
          computer_name: parent_adapter.computer_name,
          vm_id: parent_adapter.vm_id,
          id: parent_adapter.id,

          **args,

          _return_fields: self.class.attributes
        ) || {} # Unmodified object returns nothing
      )
    end
    # rubocop:enable Metrics/MethodLength

    def reload
      requires :parent_adapter

      data = service.get_vm_network_adapter_vlan(
        computer_name: parent_adapter.computer_name,
        vm_id: parent_adapter.vm_id,
        id: parent_adapter.id,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end

    private

    def merge_attributes(new_attributes = {})
      new_attributes[:allowed_vlan_id_list] = [] \
        if new_attributes[:allowed_vlan_id_list].nil? || new_attributes[:allowed_vlan_id_list] == ""
      new_attributes[:secondary_vlan_id_list] = [] \
        if new_attributes[:secondary_vlan_id_list].nil? || new_attributes[:secondary_vlan_id_list] == ""

      super
    end
  end
end
