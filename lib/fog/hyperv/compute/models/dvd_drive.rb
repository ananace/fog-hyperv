# frozen_string_literal: true

class Fog::Hyperv::Compute
  class DvdDrive < Fog::Hyperv::Model
    # @!attribute [r] id
    #   @return [String] the GUID of this DVD drive
    identity :id

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this DVD drive is attached to
    attribute :computer_name
    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this DVD drive is attached to
    attribute :vm_id

    # attribute :is_deleted
    # @!attribute [r] name
    #   @return [String] the name of this DVD drive
    attribute :name
    # @!attribute path
    #   @return [String] the path of the underlying image inserted into this DVD drive
    attribute :path
    # @!attribute pool_name
    #   @return [String] the pool storing this DVD drive's image
    attribute :pool_name
    # @!attribute controller_location
    #   @return [String] the controller location this DVD drive is attached to
    attribute :controller_location
    # @!attribute controller_number
    #   @return [Integer] the controller number this DVD drive is attached to
    attribute :controller_number, type: :integer
    # @!attribute [r] controller_type
    #   @return [:IDE, :SCSI] the controller type this DVD drive is attached to
    attribute :controller_type, type: :hypervenum, values: %i[IDE SCSI]
    # @!attribute [r] dvd_media_type
    #   @return [:None, :ISO, :Passthrough] the current type of media in the DVD drive
    attribute :dvd_media_type, type: :hypervenum, values: %i[None ISO Passthrough]
    # TODO? VM Snapshots?
    #

    def create(allow_unverified_paths: false)
      requires :vm_id
      requires_one :controller_location, :controller_number, :controller_type, :path

      merge_attributes(
        service.add_vm_dvd_drive(
          computer_name:,
          vm_id:,

          allow_unverified_paths:,
          controller_number:,
          controller_location:,
          path:,
          resource_pool_name: pool_name,

          _return_fields: self.class.attributes
        )
      )
    end

    def update
      requires :id, :vm_id

      include = []
      # Always include changes to path in the set call, in case it's set to nil
      include << :path if changed? :path

      merge_attributes(
        service.set_vm_dvd_drive(
          computer_name: old.computer_name,
          vm_id: old.vm_id,
          id: old.id,

          resource_pool_name: changed!(:pool_name),
          path: changed!(:path),
          to_controller_number: changed!(:controller_number),
          to_controller_location: changed!(:controller_location),

          _always_include: include,
          _return_fields: self.class.attributes
        )
      )
    end

    def destroy
      requires :id, :vm_id

      service.remove_vm_dvd_drive(
        computer_name:,
        vm_id:,
        id:
      )
      true
    end

    def reload
      requires :id, :vm_id

      data = service.set_vm_dvd_drive(
        computer_name:,
        vm_id:,
        id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data.attributes)
    end
  end
end
