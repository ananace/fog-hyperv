# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class DvdDrive < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] The GUID of this DVD drive
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] The name of the computer running the VM that this DVD drive is attached to
        attribute :computer_name
        # @!attribute [r] vm_id
        #   @return [String] The GUID of the VM this DVD drive is attached to
        attribute :vm_id
        # @!attribute [r] vm_name
        #   @return [String] The name of the VM this DVD drive is attached to
        attribute :vm_name

        # attribute :is_deleted
        # @!attribute [r] name
        #   @return [String] The name of this DVD drive
        attribute :name
        # @!attribute path
        #   @return [String] The path of the underlying image inserted into this DVD drive
        attribute :path
        # @!attribute pool_name
        #   @return [String] The pool storing this DVD drive's image
        attribute :pool_name
        # @!attribute controller_location
        #   @return [String] The controller location this DVD drive is attached to
        attribute :controller_location
        # @!attribute controller_number
        #   @return [Integer] The controller number this DVD drive is attached to
        attribute :controller_number, type: :integer
        # @!attribute controller_type
        #   @return [:IDE, :SCSI] The controller type this DVD drive is attached to
        attribute :controller_type, type: :enum, values: %i[IDE SCSI]
        # @!attribute [r] dvd_media_type
        #   @return [:None, :ISO, :Passthrough] The current type of media in the DVD drive
        attribute :dvd_media_type, type: :enum, values: %i[None ISO Passthrough]
        # TODO? VM Snapshots?
        #

        def save
          requires :computer_name, :vm_name

          data =
            if persisted?
              service.set_vm_dvd_drive(
                computer_name: old.computer_name,
                vm_name: old.vm_name,
                controller_number: old.controller_number,
                controller_location: old.controller_location,
                passthru: true,

                resource_pool_name: changed!(:pool_name),
                path: changed?(:path) && (path || '$null'),
                to_controller_number: changed!(:controller_number),
                to_controller_location: changed!(:controller_location),
                to_controller_type: changed!(:controller_type),

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            else
              service.add_vm_dvd_drive(
                computer_name: computer_name,
                vm_name: vm_name,
                passthru: true,

                controller_number: controller_number,
                controller_location: controller_location,
                controller_type: controller_type,
                path: path,
                resource_pool_name: pool_name,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            end

          merge_attributes(data)
          @old = dup
          self
        end

        def destroy
          requires :computer_name, :vm_name, :controller_number, :controller_location

          service.remove_vm_dvd_drive(
            computer_name: computer_name,
            vm_name: vm_name,
            controller_number: controller_number,
            controller_location: controller_location
          )
        end

        def reload
          requires :computer_name, :vm_name

          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name,
            controller_location: controller_location,
            controller_number: controller_number,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end
      end
    end
  end
end
