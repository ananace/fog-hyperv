# frozen_string_literal: true

class Fog::Hyperv::Compute
  # A collection of COM ports attached to a VM
  #
  # @note Requires a vm_id to be specified, as COM ports are not retrievable as loose objects
  class ComPorts < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::ComPort

    get_method :get_vm_com_port

    # @!attribute vm_id
    #   @return [String] the GUID of the VM containing the COM ports
    attribute :vm_id
    # @!attribute computer_name
    #   @return [String] the name of the computer running the VM that these COM ports are attached to
    attribute :computer_name

    requires :vm_id

    # Get a COM port by ID
    # @param id [String] the combined GUID of the COM port to retrieve
    def get(id, **filters)
      raise ArgumentError, 'Must provide a combined GUID' if id.nil? || id.empty?

      super(_by_id: id, **filters)
    end
  end
end
