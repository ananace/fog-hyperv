# frozen_string_literal: true

require 'fog/compute/models/server'

module Fog
  module Compute
    class Hyperv
      class Server < Fog::Compute::Server
        extend Fog::Hyperv::ModelExtends
        include Fog::Hyperv::ModelIncludes

        VM_STATUS_ENUM_VALUES = {
          Unknown: 1,
          Running: 2,
          Off: 3,
          Stopping: 4,
          Saved: 6,
          Paused: 9,
          Starting: 10,
          Reset: 11,
          Saving: 32773,
          Pausing: 32776,
          Resuming: 32777,
          FastSaved: 32779,
          FastSaving: 32780,
          ForceShutdown: 32781,
          ForceReboot: 32782,
          RunningCritical: 32783,
          OffCritical: 32784,
          StoppingCritical: 32785,
          SavedCritical: 32786,
          PausedCritical: 32787,
          StartingCritical: 32788,
          ResetCritical: 32789,
          SavingCritical: 32790,
          PausingCritical: 32791,
          ResumingCritical: 32792,
          FastSavedCritical: 32793,
          FastSavingCritical: 32794,
        }.freeze

        identity :id, type: :string

        attribute :name, type: :string
        attribute :computer_name, type: :string
        attribute :com_port1
        attribute :com_port2
        attribute :dynamic_memory_enabled, type: :boolean, default: false
        attribute :generation, type: :integer, default: 1 # 1 => bios, 2 => uefi
        attribute :is_clustered, type: :boolean, default: false
        attribute :state, type: :enum, values: VM_STATUS_ENUM_VALUES
        attribute :status, type: :string
        attribute :memory_assigned, type: :integer
        attribute :memory_maximum, type: :integer, default: 17_179_869_184
        attribute :memory_minimum, type: :integer, default: 536_870_912
        attribute :memory_startup, type: :integer, default: 536_870_912
        attribute :notes, type: :string
        attribute :processor_count, type: :integer, default: 1

        lazy_attributes :network_adapters,
          :dvd_drives,
          :hard_drives,
          :floppy_drive

        attr_accessor :cluster_name

        %i(network_adapters dvd_drives floppy_drives hard_drives vhds).each do |attr|
          define_method attr do
            if persisted?
              attributes[attr] ||= service.send(attr, vm: self)
            else
              attributes[attr] ||= [] unless persisted?
            end
          end
        end

        %i(com_port1 com_port2).each do |attr|
          define_method "#{attr}=".to_sym do |data|
            attributes[attr] = Fog::Compute::Hyperv::ComPort.new(data) if data.is_a?(Hash)
          end
        end

        def initialize(attrs = {})
          super

          @cluster = attrs.delete :cluster
          @computer = attrs.delete :computer
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

        # TODO: Do this properly
        def set_vlan(vlan_id, options = {})
          requires :name, :computer_name
          if vlan_id
            options[:access] = true
            options[:vlan_id] = vlan_id
          else
            options[:untagged] = true
          end

          service.set_vm_network_adapter_vlan options.merge(
            vm_name: name,
            computer_name: computer_name
          )
        end

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
            .reject { |a| a =~ /^(169\.254|fe[89ab][0-9a-f])/ }
            .first
        end
      end
    end
  end
end
