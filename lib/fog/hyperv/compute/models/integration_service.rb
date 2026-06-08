# frozen_string_literal: true

class Fog::Hyperv::Compute
  class IntegrationService < Fog::Hyperv::Model
    # rubocop:disable Layout/HashAlignment

    # Integration service statuses
    # @note Defined by Microsoft.HyperV.PowerShell.VMIntegrationComponentOperationalStatus
    INTEGRATION_SERVICE_STATUS_ENUM_VALUES = {
      Ok:                    2,
      Degraded:              3,
      Error:                 6,
      NonRecoverableError:   7,
      NoContact:             12,
      LostCommunication:     13,
      Disabled:              32_896,
      ProtocolMismatch:      32_775,
      ApplicationCritical:   32_782,
      CommunicationTimedOut: 32_783,
      CommunicationFailed:   32_784
    }.freeze
    # rubocop:enable Layout/HashAlignment

    # @!attribute [r] name
    #   @return [String] the name of the integration service
    identity :name

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this integration service is attached to
    attribute :computer_name
    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this integration service is attached to
    attribute :vm_id

    # @!attribute enabled
    #   @return [Boolean] if the integration service is enabled or not
    attribute :enabled, type: :boolean
    # @!attribute [r] operational_status
    #   @return [Symbol] the statuses of the integration service
    #   @see INTEGRATION_SERVICE_STATUS_ENUM_VALUES
    attribute :operational_status, type: :hypervenumarray, values: INTEGRATION_SERVICE_STATUS_ENUM_VALUES

    def update
      requires :name, :vm_id

      return self unless changed? :enabled

      method = enabled ? :enable : :disable
      service.send(:"#{method}_vm_integration_service", computer_name: computer_name, vm_id: vm_id, name: name)

      old.enabled = attributes[:enabled]
      self
    end

    def reload
      requires :name, :vm_id

      data = service.get_vm_integration_service computer_name: computer_name, vm_id: vm_id, name: name
      return unless data

      merge_attributes(data)
    end

    protected

    def merge_attributes(new_attributes = {})
      new_attributes[:operational_status] = [] if new_attributes[:operational_status] == ''

      super
    end
  end
end
