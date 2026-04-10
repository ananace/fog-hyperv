# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      # A hard drive attached to a VM
      class HardDrive < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] the GUID of this hard drive
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] the name of the computer running the VM that this hard drive is attached to
        attribute :computer_name
        # @!attribute [r] vm_id
        #   @return [String] the GUID of the VM this hard drive is attached to
        attribute :vm_id
        # @!attribute [r] vm_name
        #   @return [String] the name of the VM this hard drive is attached to
        attribute :vm_name

        # @!attribute controller_location
        #   @return [String] the controller location this hard drive is attached to
        attribute :controller_location
        # @!attribute controller_location
        #   @return [Integer] the controller number this hard drive is attached to
        attribute :controller_number, type: :integer
        # @!attribute controller_type
        #   @return [:IDE, :SCSI] the controller type this hard drive is attached to
        attribute :controller_type, type: :enum, values: %i[IDE SCSI]
        # @!attribute disk
        #   @return [Object] the attached disk
        attribute :disk
        # attribute :is_deleted
        # @!attribute maximum_iops
        #   @return [Integer] the maximum number of IOPS allocated for this hard drive
        attribute :maximum_iops, type: :integer
        # @!attribute minimum_iops
        #   @return [Integer] the minimum number of IOPS allocated for this hard drive
        attribute :minimum_iops, type: :integer
        # @!attribute [r] name
        #   @return [String] the name of this hard drive
        attribute :name
        # @!attribute path
        #   @return [String] the path to the VHD file for this hard drive
        attribute :path
        # @!attribute pool_name
        #   @return [String] the name of the pool storing this hard drive's image
        attribute :pool_name
        # @!attribute support_persistent_reservations
        #   @return [Boolean] does the underlying hard drive support SCSI persistent reservations.
        #     Should be set when multiple VMs share the same underlying disk.
        attribute :support_persistent_reservations
        # TODO? VM Snapshots?

        # @!attribute [r] vhd
        # @return [Vhd] the VHD that this hard drive uses
        def vhd
          return nil unless path && computer_name

          @vhd ||= service.vhds.get(path, computer_name: computer_name)
        end

        # @return [Boolean] does the hard drive have a VHD attached?
        def vhd?
          !vhd.nil?
        end

        # @!attribute size_bytes
        # @return [Integer] the size of the underlying VHD
        def size_bytes
          vhd&.size_bytes || 0
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

              disk_number: changed?(:disk) && disk&.number,
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
              attributes
                .slice(*possible)
                .merge(
                  disk_number: disk&.number,
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

        def destroy(underlying: false)
          return unless persisted?

          service.remove_vm_hard_disk_drive(
            computer_name: computer_name,
            vm_name: vm_name,

            controller_location: controller_location,
            controller_number: controller_number,
            controller_type: controller_type
          )

          return unless underlying && vhd?

          vhd.destroy
        end
      end
    end
  end
end
