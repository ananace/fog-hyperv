module Fog
  module Compute
    class Hyperv
      class Host < Fog::Hyperv::Model
        identity :name

        attribute :computer_name
        attribute :fully_qualified_domain_name
        attribute :logical_processor_count
        attribute :memory_capacity
        attribute :mac_address_minimum
        attribute :mac_address_maximum
        attribute :maximum_storage_migrations
        attribute :maximum_virtual_machine_migrations
        attribute :virtual_hard_disk_path
        attribute :virtual_machine_path
      end
    end
  end
end
