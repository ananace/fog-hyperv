# frozen_string_literal: true

class Fog::Hyperv::Compute
  # The configuration of a virtual COM port on a VM
  #
  # @see https://learn.microsoft.com/en-us/powershell/module/hyper-v/set-vmcomport for set-request
  class ComPort < Fog::Hyperv::Model
    # @!attribute [r] id
    #   @return [String] the combined GUID of this COM port
    identity :id, type: :string

    # @!attribute [r] vm_id
    #   @return [String] the GUID of the VM this COM port is attached to
    attribute :vm_id, type: :string
    # @!attribute [r] computer_name
    #   @return [String] the name of the computer running the VM that this COM port is attached to
    attribute :computer_name, type: :string

    # @!attribute debugger_mode
    #   @return [String] is a debugger enabled on this COM port
    attribute :debugger_mode, type: :hypervenum, values: ON_OFF_STATE_ENUM_VALUES
    # @!attribute [r] name
    #   @return [String] the name of this COM port
    attribute :name, type: :string
    # @!attribute path
    #   @return [String] the path this COM port is attached to
    attribute :path

    # Save any modifications to Hyper-V
    def update
      requires :vm_id, :id

      data = service.set_vm_com_port(
        computer_name:,
        vm_id:,
        id:,

        debugger_mode: changed!(:debugger_mode),
        path: changed!(:path),

        _return_fields: self.class.attributes
      )

      merge_attributes(data)
      self
    end

    # Reload attributes from Hyper-V
    def reload
      requires :vm_id, :id

      data = service.get_vm_com_port(
        computer_name:,
        vm_id:,
        id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
    end

    private

    def merge_attributes(new_attributes = {})
      new_attributes[:path] = nil if new_attributes[:path] == ''

      super
    end
  end
end
