# frozen_string_literal: true

require 'fog/hyperv/model'

class Fog::Hyperv::Compute
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

    # @!attribute controller_location
    #   @return [String] the controller location this hard drive is attached to
    attribute :controller_location
    # @!attribute controller_number
    #   @return [Integer] the controller number this hard drive is attached to
    attribute :controller_number, type: :integer
    # @!attribute controller_type
    #   @return [:IDE, :SCSI] the controller type this hard drive is attached to
    attribute :controller_type, type: :hypervenum, values: %i[IDE SCSI]
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

    attribute :allow_unverified_paths, type: :boolean

    has_one :vhd, :vhds

    def initialize(attributes = {})
      vhd = attributes[:vhd]
      attributes[:path] ||= vhd&.path

      super
    end

    # @!attribute vhd
    # @return [Vhd,nil] the VHD that is attached to this hard drive
    def vhd
      return associations[:vhd] if associations[:vhd]
      return unless path

      associations[:vhd] = service.vhds.get(path, computer_name:)
    end

    def vhd=(new_vhd)
      raise ArgumentError, 'Must be a VHD' unless new_vhd.nil? || new_vhd.is_a?(Vhd)

      associations[:path] = new_vhd&.path
      associations[:vhd] = new_vhd
    end

    # @return [Boolean] does the hard drive have a VHD attached?
    def vhd?
      !vhd.nil?
    end

    # @!attribute [r] size_bytes
    # @return [Integer,nil] the size of the underlying VHD if any
    def size_bytes
      vhd&.size
    end

    def create
      requires :vm_id
      requires_one :controller_location, :controller_number, :controller_type, :path

      if associations[:vhd]
        vhd.save if !vhd.persisted? || vhd.dirty?
        attributes[:path] ||= vhd.path
      end

      merge_attributes(
        service.add_vm_hard_disk_drive(
          computer_name:,
          vm_id:,

          allow_unverified_paths:,
          controller_location:,
          controller_number:,
          controller_type:,
          # disk_number: disk&.number,
          maximum_iops:,
          minimum_iops:,
          path:,
          resource_pool_name: pool_name,

          _return_fields: self.class.attributes - %i[allow_unverified_paths vhd]
        )
      )
    end

    def update
      requires :id, :vm_id

      merge_attributes(
        service.set_vm_hard_disk_drive(
          computer_name: old.computer_name,
          vm_id: old.vm_id,
          id: old.id,

          allow_unverified_paths:,
          # disk_number: changed?(:disk) && disk&.number,
          maximum_iops: changed!(:maximum_iops),
          minimum_iops: changed!(:minimum_iops),
          path: changed!(:path),
          resource_pool_name: changed!(:pool_name),
          support_persistent_reservations: changed!(:support_persistent_reservations),
          to_controller_location: changed!(:controller_location),
          to_controller_number: changed!(:controller_number),
          to_controller_type: changed!(:controller_type),

          _return_fields: self.class.attributes - %i[allow_unverified_paths vhd]
        )
      )

      if associations[:vhd]
        vhd.save if !vhd.persisted? || vhd.dirty?
        associations[:vhd] = nil if changed?(:path)
      end
      self
    end

    def reload
      requires :id, :vm_id

      data = service.get_vm_hard_disk_drive(
        computer_name:,
        vm_id:,
        id:,

        _return_fields: self.class.attributes - %i[allow_unverified_paths vhd]
      )
      return unless data

      merge_attributes(data)
    end

    def destroy(underlying: false)
      return unless persisted?

      requires :id, :vm_id

      service.remove_vm_hard_disk_drive(
        computer_name:,
        vm_id:,
        id:
      )
      vhd.destroy if underlying && vhd?
      true
    end
  end
end
