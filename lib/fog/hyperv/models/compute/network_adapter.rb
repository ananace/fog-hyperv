module Fog
  module Compute
    class Hyperv
      class NetworkAdapter < Fog::Model
        identity :id

        attribute :acl_list
        attribute :computer_name
        attribute :connected
        attribute :ip_addresses
        attribute :is_deleted
        attribute :is_external_adapter
        attribute :is_legacy
        attribute :isolation_setting # Might need lazy loading
        attribute :mac_address
        attribute :name
        attribute :status
        attribute :switch_id
        attribute :switch_name
        attribute :vm_id
        attribute :vm_name
        attribute :vlan_setting # Might need lazy loading

        def connect(switch, options = {})
          requires :name, :computer_name, :vm_name

          service.connect_vm_network_adapter options.merge(
            computer_name: computer_name,
            name: name,
            switch_name: switch,
            vm_name: vm_name
          )
        end

        def disconnect(options = {})
          requires :name, :computer_name, :vm_name

          service.disconnect_vm_network_adapter options.merge(
            computer_name: computer_name,
            name: name,
            vm_name: vm_name
          )
        end
      end
    end
  end
end
