# frozen_string_literal: true

class Fog::Hyperv::Compute
  class FloppyDrive < Fog::Hyperv::Model
    # @!attribute [r] id
    #   @return [String] the combined GUID of this floppy drive
    identity :id, type: :string

    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this BIOS configuration is attached to
    attribute :vm_id, type: :string
    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this BIOS configuration is attached to
    attribute :computer_name, type: :string

    # @!attribute [r] name
    #   @return [String] the name of this floppy drive
    attribute :name, type: :string
    # @!attribute path
    #   @return [String] the path this floppy drive is serving
    attribute :path
    # @!attribute pool_name
    #   @return [String] the pool storing this floppy drive's image
    attribute :pool_name

    def update
      requires :vm_id, :id

      changes = {
        resource_pool_name: changed!(:pool_name)
      }.compact
      changes[:path] = path if changed? :path
      return self unless changes.any?

      merge_attributes(
        service.set_vm_floppy_disk_drive(
          computer_name:,
          vm_id:,
          id:,

          **changes,

          _always_include: changes.keys,
          _return_fields: self.class.attributes
        )
      )
    end

    def reload
      requires :vm_id, :id

      data = service.get_vm_floppy_disk_drive(
        computer_name:,
        vm_id:,
        id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end
  end
end
