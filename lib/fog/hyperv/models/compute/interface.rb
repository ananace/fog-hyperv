module Fog
  module Compute
    class Hyperv
      class Interface < Fog::Model
        identity :id

        attribute :computer_name
        attribute :connected
        attribute :ip_addresses
        attribute :is_deleted
        attribute :is_external_adapter
        attribute :is_legacy
        attribute :isolation_setting # Might need lazy loading
        attribute :key
        attribute :mac_address
        attribute :name
        attribute :status
        attribute :switch_id
        attribute :switch_name
        attribute :vm_id
        attribute :vm_name
        attribute :vlan_setting # Might need lazy loading
      end
    end
  end
end
