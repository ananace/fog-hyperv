# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class FloppyDrive < Fog::Hyperv::Model
        # @!attribute [r] id
        #   @return [String] The GUID of this floppy drive
        identity :id

        # @!attribute [r] computer_name
        #   @return [String] The name of the computer running the VM that this floppy drive is attached to
        attribute :computer_name
        # @!attribute [r] vm_id
        #   @return [String] The GUID of the VM this floppy drive is attached to
        attribute :vm_id
        # @!attribute [r] vm_name
        #   @return [String] The name of the VM this floppy drive is attached to
        attribute :vm_name

        # @!attribute [r] disk
        #   @return [String] The disk in this floppy drive
        attribute :disk
        # attribute :is_deleted
        # @!attribute [r] name
        #   @return [String] The name of this floppy drive
        attribute :name
        # @!attribute path
        #   @return [String] The path of the underlying image inserted into this floppy drive
        attribute :path
        # @!attribute pool_name
        #   @return [String] The pool storing this floppy drive's image
        attribute :pool_name
        # TODO? VM Snapshots?
        #

        def save
          raise Fog::Hyperv::Errors::ServiceError, "Can't create new floppy drives" unless persisted?

          requires :computer_name, :vm_name

          data =
            service.set_vm_floppy_disk_drive(
              computer_name: old.computer_name,
              vm_name: old.vm_name,
              passthru: true,

              resource_pool_name: changed!(:pool_name),
              path: changed?(:path) && (path || '$null'),

              _return_fields: self.class.attributes,
              _json_depth: 1
            )

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          data = collection.get(
            computer_name: computer_name,
            vm_name: vm_name
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end
      end
    end
  end
end
