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
          Saving: 32_773,
          Pausing: 32_776,
          Resuming: 32_777,
          FastSaved: 32_779,
          FastSaving: 32_780,
          ForceShutdown: 32_781,
          ForceReboot: 32_782,
          RunningCritical: 32_783,
          OffCritical: 32_784,
          StoppingCritical: 32_785,
          SavedCritical: 32_786,
          PausedCritical: 32_787,
          StartingCritical: 32_788,
          ResetCritical: 32_789,
          SavingCritical: 32_790,
          PausingCritical: 32_791,
          ResumingCritical: 32_792,
          FastSavedCritical: 32_793,
          FastSavingCritical: 32_794
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

        %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
          define_method attr do
            if persisted?
              attributes[attr] ||= service.send(attr, vm: self)
            else
              attributes[attr] ||= [].tap do |arr|
                arr.instance_variable_set :@klass, Fog::Compute::Hyperv.const_get(
                  Fog::Hyperv.camelize(attr.to_s.chop).to_sym
                )
                arr.instance_variable_set :@vm, self
                arr.instance_variable_set :@service, service

                arr.instance_eval do
                  def new(**attributes)
                    self << @klass.new(
                      attributes.merge(
                        computer_name: @vm.computer_name,
                        vm_name: @vm.name,
                        vm: @vm,
                        service: @service
                      )
                    )
                  end
                end
              end
            end
          end
        end

        %i[com_port1 com_port2].each do |attr|
          define_method "#{attr}=".to_sym do |data|
            attributes[attr] = Fog::Compute::Hyperv::ComPort.new(data) if data.is_a?(Hash)
          end
        end

        def initialize(attrs = {})
          super

          %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
            next unless attrs.key? attr

            attributes[attr] = attrs.delete(attr).map do |data|
              service.public_send(attr, vm: self).new(data)
            end
          end

          @cluster = attrs.delete :cluster
          @computer = attrs.delete :computer
        end

        def bios
          @bios ||= begin
            if generation == 1
              klass = Fog::Compute::Hyperv::Bios
              method = :get_vm_bios
            else
              klass = Fog::Compute::Hyperv::Firmware
              method = :get_vm_firmware
            end

            klass.new(
              service.public_send(
                method,
                computer_name: computer_name,
                vm_name: name,

                _return_fields: klass.attributes
              ).merge(service: service)
            )
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

          if !persisted?
            # TODO: Apply predefined config onto created VM
            usable = %i[name memory_startup generation boot_device switch_name no_vhd new_vhd_path new_vhd_size_bytes].freeze
            data = service.new_vm \
              attributes.select { |k, _v| usable.include? k }
                        .merge(options)
                        .merge(_return_fields: self.class.attributes, _json_depth: 1)
          else
            data = service.set_vm options.merge(
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

          %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
            attributes[attr]&.select(&:dirty?)&.each(&:save)

            if attr == :vhds && attributes[attr]
              attributes[attr].each { |vhd| hard_drives.new(path: vhd.path).save }
            end

            # Reset pre-persist lazy attributes to become true collections
            attributes[attr] = nil if attributes[attr].class == Array
          end

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

        def public_ip_addresses
          ip_addresses
            .reject { |a| a =~ /^(169\.254|fe[89ab][0-9a-f])/ }
        end
      end
    end
  end
end
