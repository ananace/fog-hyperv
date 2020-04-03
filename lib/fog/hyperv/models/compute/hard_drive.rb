# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class HardDrive < Fog::Hyperv::Model
        identity :id

        attribute :computer_name
        attribute :controller_location
        attribute :controller_number, type: :integer
        attribute :controller_type, type: :enum, values: %i[IDE SCSI]
        attribute :disk
        # attribute :is_deleted
        attribute :maximum_iops, type: :integer
        attribute :minimum_iops, type: :integer
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :support_persistent_reservations
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?

        def vhd
          return nil unless path && computer_name
          @vhd ||= service.vhds.get(path, computer_name: computer_name)
        end

        def size_bytes
          vhd && vhd.size_bytes || 0
        end

        def size_bytes=(bytes)
          vhd.size_bytes = bytes if vhd
        end

        def save
          requires :computer_name, :vm_name

          if persisted?
            data = service.set_vm_hard_disk_drive(
              computer_name: old.computer_name,
              vm_name: old.vm_name,
              controller_location: old.controller_location,
              controller_number: old.controller_number,
              controller_type: old.controller_type,
              passthru: true,

              disk_number: changed?(:disk) && disk && disk.number,
              maximum_iops: changed!(:maximum_iops),
              minimum_iops: changed!(:minimum_iops),
              path: changed!(:path),
              resource_pool_name: changed!(:pool_name),
              support_persistent_reservations: changed!(:support_persistent_reservations),
              to_controller_location: changed!(:controller_location),
              to_controller_number: changed!(:controller_number),
              to_controller_type: changed!(:controller_type),

              _return_fields: self.class.attributes,
              _json_depth: 1
            )
            @vhd = nil if changed?(:path)
          else
            possible = %i[computer_name controller_location controller_number controller_type path vm_name].freeze
            data = service.add_vm_hard_disk_drive(
              attributes.select { |k, _v| possible.include? k }.merge(
                disk_number: disk && disk.number,
                resource_pool_name: pool_name,

                passthru: true,
                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            )
          end

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name,
            controller_location: controller_location,
            controller_number: controller_number,
            controller_type: controller_type
          )

          merge_attributes(data.attributes)
          @old = data
          self
        end

        def destroy
          return unless persisted?

          service.remove_vm_hard_disk_drive(
            computer_name: computer_name,
            vm_name: vm_name,

            controller_location: controller_location,
            controller_number: controller_number,
            controller_type: controller_type
          )
        end
      end
    end
  end
end
