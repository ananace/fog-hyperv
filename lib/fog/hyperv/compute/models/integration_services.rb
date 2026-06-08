# frozen_string_literal: true

class Fog::Hyperv::Compute
  # A collection of integration services available for a VM
  #
  # @note Requires a vm_id to be specified, as integration services are not retrievable as loose objects
  class IntegrationServices < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::IntegrationService

    get_method :get_vm_integration_service

    # @!attribute vm_id
    #   @return [String] the GUID of the VM containing the COM ports
    attribute :vm_id
    # @!attribute computer_name
    #   @return [String] the name of the computer running the VM that these COM ports are attached to
    attribute :computer_name

    requires :vm_id

    # Get an integration service by name
    # @param id [String] the name of the integration service to retrieve
    def get(name, **filters)
      raise ArgumentError, 'Must provide a name' if name.nil? || name.empty?

      super(name: name, **filters)
    end
  end
end
