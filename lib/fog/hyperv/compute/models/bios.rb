# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Bios < Fog::Hyperv::Model
        # @!attribute [r] vm_id
        #   @return [String] The GUID of the VM this BIOS configuration is attached to
        identity :vm_id, type: :string

        # @!attribute [r] computer_name
        #   @return [String] The name of the computer running the VM that this BIOS configuration is attached to
        attribute :computer_name, type: :string
        # @!attribute [r] vm_name
        #   @return [String] The name of the VM this BIOS configuration is attached to
        attribute :vm_name, type: :string

        # attribute :is_deleted, type: :boolean
        # @!attribute num_lock_enabled
        #   @return [Boolean] Should num-lock be enabled on boot
        attribute :num_lock_enabled, type: :boolean
        # TODO? Enum values; :CD, :IDE, :LegacyNetworkAdapter, :Floppy (, :VHD, :NetworkAdapter)
        # @!attribute startup_order
        #   @return [Array<String>] The boot order of the VM
        attribute :startup_order, type: :array

        # @!attribute [r] vm
        # @return [Server] The VM this BIOS configuration is attached to
        attr_reader :computer, :vm

        def initialize(args = {})
          super
          @computer = args.delete :computer
          @vm = args.delete :vm
        end

        def save
          requires :computer_name, :vm_name

          raise Fog::Hyperv::Errors::ServiceError, "Can't create Bios instances" unless persisted?

          data = service.set_vm_bios(
            computer_name: computer_name,
            vm_name: vm_name,
            passthru: true,

            disable_num_lock: changed?(:num_lock_enabled) && !num_lock_enabled,
            enable_num_lock: changed?(:num_lock_enabled) && num_lock_enabled,
            startup_order: changed!(:startup_order),

            _return_fields: self.class.attributes,
            _json_depth: 1
          )

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          requires :computer_name, :vm_name

          data = service.get_vm_bios(
            computer_name: computer_name,
            vm_name: vm_name,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )
          merge_attributes(data)
          self
        end
      end
    end
  end
end
