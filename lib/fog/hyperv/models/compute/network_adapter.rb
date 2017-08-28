module Fog
  module Compute
    class Hyperv
      class NetworkAdapter < Fog::Hyperv::Model
        identity :id

        # attribute :acl_list
        attribute :computer_name
        attribute :connected
        attribute :dynamic_mac_address_enabled, type: :boolean, default: true
        attribute :ip_addresses
        # attribute :is_deleted
        attribute :is_external_adapter
        attribute :is_legacy
        attribute :is_management_os
        # attribute :isolation_setting # Might need lazy loading
        attribute :mac_address
        attribute :name, type: :string, default: 'Network Adapter'
        # attribute :router_guard, type: :enum, values: [ :On, :Off ]
        # attribute :status, type: :enum, values: STATUS_ENUM_VALUES
        attribute :switch_id
        attribute :switch_name, type: :string
        attribute :vm_id
        attribute :vm_name
        # attribute :vlan_setting # Might need lazy loading

        def connect(switch, options = {})
          requires :name, :computer_name, :vm_name

          switch = switch.name if switch.is_a? Fog::Compute::Hyperv::Switch

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

        def switch
          service.switches.get switch_name, computer_name: computer_name if switch_name
        end

        def ip_addresses
          attributes[:ip_addresses] = [] \
            if attributes[:ip_addresses] == ''
          attributes[:ip_addresses]
        end

        def save
          requires :name, :computer_name, :vm_name

          data = \
            if !persisted?
              service.add_vm_network_adapter(
                computer_name: computer_name,
                name: name,
                vm_name: vm_name,
                passthru: true,

                dynamic_mac_address: dynamic_mac_address_enabled,
                static_mac_address: !dynamic_mac_address_enabled && mac_address,
                switch_name: switch_name,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            else
              ret = service.set_vm_network_adapter(
                computer_name: old.computer_name,
                name: old.name,
                vm_name: old.vm_name,
                passthru: true,

                dynamic_mac_address: changed?(:dynamic_mac_address_enabled) && dynamic_mac_address_enabled, 
                static_mac_address: (changed?(:mac_address) || changed?(:dynamic_mac_address_enabled)) && !dynamic_mac_address_enabled && mac_address,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )

              if changed?(:switch_name)
                service.disconnect_vm_network_adapter(
                  computer_name: ret.computer_name,
                  name: ret.name,
                  vm_name: ret.vm_name
                ) unless switch_name

                service.connect_vm_network_adapter(
                  computer_name: ret.computer_name,
                  name: ret.name,
                  vm_name: ret.vm_name,
                  switch_name: switch_name
                ) if switch_name
              end
              ret[:switch_name] = switch_name
              ret
            end

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
            vm_name: vm_name
          )
          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
