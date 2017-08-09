module Fog
  module Compute
    class Hyperv
      class Bios < Fog::Hyperv::Model
        identity :vm_id, type: :string

        attribute :computer_name, type: :string
        attribute :is_deleted, type: :boolean
        attribute :num_lock_enabled, type: :boolean
        # TODO? :CD, :IDE, :LegacyNetworkAdapter, :Floppy (, :VHD, :NetworkAdapter)
        attribute :startup_order, type: :array
        attribute :vm_name, type: :string

        def save
          data = service.set_vm_bios(
            computer_name: computer_name,
            disable_num_lock: !num_lock_enabled,
            enable_num_lock: num_lock_enabled,
            startup_order: startup_order,
            vm_name: vm_name,
            passthru: true,
            _return_fields: self.class.attributes,
            _json_depth: 1
          )
          merge_attributes(data)
          self
        end

        def reload
          data = service.get_vm_bios(
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
