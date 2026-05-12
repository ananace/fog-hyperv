# frozen_string_literal: true

class Fog::Hyperv::Compute
  # A collection of DVD drives attached to a VM
  #
  # @note Requires a vm_id to be specified, as DVD drives are not retrievable as loose objects
  class DvdDrives < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::DvdDrive

    get_method :get_vm_dvd_drive

    # @!attribute vm_id
    #   @return [String] the GUID of the VM containing the COM ports
    attribute :vm_id
    # @!attribute computer_name
    #   @return [String] the name of the computer running the VM that these COM ports are attached to
    attribute :computer_name

    requires :vm_id

    # Get a DVD drive by ID
    # @param id [String] the GUID of the DVD drive to retrieve
    def get(id, **filters)
      raise ArgumentError, 'Must provide a GUID' if id.nil? || id.empty?

      super(_by_id: id, **filters)
    end
  end
end
