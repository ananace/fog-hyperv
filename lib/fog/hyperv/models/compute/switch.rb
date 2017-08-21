module Fog
  module Compute
    class Hyperv
      class Switch < Fog::Hyperv::Model
        identity :id

        attribute :computer_name
        # attribute :default_flow_minimum_bandwidth_absolute
        # attribute :default_flow_minimum_bandwidth_weight
        # attribute :is_deleted
        attribute :name
        attribute :net_adapter_interface_description
        attribute :notes
        attribute :switch_type, type: :enum, values: [ :Private, :Internal, :External ]

        def save
          requires :name

          data = if persisted?
                   service.set_vm_switch(
                     computer_name: computer_name,
                     default_flow_minimum_bandwidth_absolute: default_flow_minimum_bandwidth_absolute,
                     default_flow_minimum_bandwidth_weight: default_flow_minimum_bandwidth_weight,
                     name: name,
                     net_adapter_interface_description: net_adapter_interface_description,
                     notes: notes,
                     switch_type: !net_adapter_interface_description && switch_type,
                     passthru: true,
                     _return_fields: self.class.attributes,
                     _json_depth: 1
                   )
                 else
                   service.new_vm_switch(
                     computer_name: computer_name,
                     name: name,
                     net_adapter_interface_description: net_adapter_interface_description,
                     notes: notes,
                     switch_type: !net_adapter_interface_description && switch_type,
                     _return_fields: self.class.attributes,
                     _json_depth: 1
                   )
                 end
          merge_attributes(data)
          self
        end

        def reload
          data = collection.get(
            name,
            computer_name: computer_name
          )
          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
