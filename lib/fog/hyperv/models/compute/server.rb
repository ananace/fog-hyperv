require 'fog/compute/models/server'

module Fog
  module Compute
    class Hyperv
      class Server < Fog::Compute::Server
        extend Fog::Hyperv::ModelExtends
        include Fog::Hyperv::ModelIncludes

        VM_STATUS_ENUM_VALUES = {
          1     => :Unknown,
          2     => :Running,
          3     => :Off,
          4     => :Stopping,
          6     => :Saved,
          9     => :Paused,
          10    => :Starting,
          11    => :Reset,
          32773 => :Saving,
          32776 => :Pausing,
          32777 => :Resuming,
          32779 => :FastSaved,
          32780 => :FastSaving,
          32781 => :ForceShutdown,
          32782 => :ForceReboot,
          32783 => :RunningCritical,
          32784 => :OffCritical,
          32785 => :StoppingCritical,
          32786 => :SavedCritical,
          32787 => :PausedCritical,
          32788 => :StartingCritical,
          32789 => :ResetCritical,
          32790 => :SavingCritical,
          32791 => :PausingCritical,
          32792 => :ResumingCritical,
          32793 => :FastSavedCritical,
          32794 => :FastSavingCritical
        }.freeze

        identity :id, type: :string

        attribute :name, type: :string
        attribute :computer_name, type: :string
        attribute :com_port1
        attribute :com_port2
        attribute :dynamic_memory_enabled, type: :boolean, default: false
        attribute :generation, type: :integer, default: 1 # 1 => bios, 2 => uefi
        attribute :state, type: :enum, values: VM_STATUS_ENUM_VALUES
        attribute :status, type: :string
        attribute :memory_assigned, type: :integer
        attribute :memory_maximum, type: :integer, default: 171_798_691_84
        attribute :memory_minimum, type: :integer, default: 536_870_912
        attribute :memory_startup, type: :integer, default: 536_870_912
        attribute :notes, type: :string
        attribute :processor_count, type: :integer, default: 1

        lazy_attributes :network_adapters,
                        :dvd_drives,
                        :hard_drives,
                        :floppy_drive

        %i(network_adapters dvd_drives floppy_drives hard_drives vhds).each do |attr|
          define_method attr do
            attributes[attr] ||= [] unless persisted?
            attributes[attr] ||= service.send(attr, vm: self)
          end
        end

        %i(com_port1 com_port2).each do |attr|
          define_method "#{attr}=".to_sym do |data|
            attributes[attr] = Fog::Compute::Hyperv::ComPort.new(data) if data.is_a?(Hash)
          end
        end

        def bios
          @bios ||= begin
            if generation == 1
              Fog::Compute::Hyperv::Bios.new(service.get_vm_bios(computer_name: computer_name, vm_name: name).merge service: service)
            elsif generation == 2
              Fog::Compute::Hyperv::Firmware.new(service.get_vm_firmware(computer_name: computer_name, vm_name: name).merge service: service)
            end
          end
        end
        alias firmware :bios

        alias vm_id :id
        alias vm_name :name

        def start(options = {})
          requires :name, :computer_name
          service.start_vm options.merge(
            name: name,
            computer_name: computer_name
          )
        end

        def stop(options = {})
          requires :name, :computer_name
          service.stop_vm options.merge(
            name: name,
            computer_name: computer_name
          )
        end

        def restart(options = {})
          requires :name, :computer_name
          service.restart_vm options.merge(
            name: name,
            computer_name: computer_name
          )
        end
        alias reboot :restart

        def destroy(options = {})
          requires :name, :computer_name
          stop turn_off: true if ready?
          service.remove_vm options.merge(
            name: name,
            computer_name: computer_name
          )
        end

        def add_interface(options = {})
          network_adapters.create options
        end

        def save(options = {})
          requires :name
          logger.debug "Saving server with; #{attributes}, #{options}"

          data = \
            if !persisted?
              usable = %i(name memory_startup generation boot_device switch_name no_vhd new_vhd_path new_vhd_size_bytes).freeze
              service.new_vm \
                attributes.select { |k, _v| usable.include? k }
                .merge(options)
                .merge(_return_fields: self.class.attributes, _json_depth: 1)
            else
              service.set_vm options.merge(
                computer_name: old.computer_name,
                name: old.name,
                passthru: true,

                processor_count: changed!(:processor_count),
                dynamic_memory: changed?(:dynamic_memory_enabled) && dynamic_memory_enabled,
                static_memory: changed?(:dynamic_memory_enabled) && !dynamic_memory_enabled,
                memory_minimum_bytes: changed?(:memory_minimum) && dynamic_memory_enabled && memory_minimum,
                memory_maximum_bytes: changed?(:memory_maximum) && dynamic_memory_enabled && memory_maximum,
                memory_startup_bytes: changed!(:memory_startup),
                notes: changed!(:notes),
                new_name: changed!(:name),

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            end

          merge_attributes(data)
          @old = dup
          self
        end

        def reload
          data = collection.get id

          clear_lazy
          merge_attributes(data.attributes)
          @old = data
          self
        end

        def ready?
          state_num == 2
        end

        def mac_addresses
          network_adapters.map(&:mac_address)
        end

        def ip_addresses
          network_adapters.map(&:ip_addresses).flatten
        end

        def public_ip_address
          ip_addresses
            .reject { |a| a =~ /^(169\.254|fe80)/ }
            .first
        end
      end
    end
  end
end
