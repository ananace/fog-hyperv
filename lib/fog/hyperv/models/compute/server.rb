require 'fog/compute/models/server'

module Fog
  module Compute
    class Hyperv
      class Server < Fog::Compute::Server
        extend Fog::Hyperv::ModelExtends
        include Fog::Hyperv::ModelIncludes
        identity :id, type: :string

        attribute :name
        attribute :computer_name
        attribute :dynamic_memory_enabled, type: :boolean, default: false
        attribute :floppy_drive
        attribute :generation, type: :integer, default: 1 # 1 => bios, 2 => uefi
        attribute :state
        attribute :status
        attribute :memory_assigned, type: :integer
        attribute :memory_maximum, type: :integer
        attribute :memory_minimum, type: :integer
        attribute :memory_startup, type: :integer, default: 536_870_912
        attribute :notes, type: :string
        attribute :processor_count, type: :integer, default: 1

        attribute :network_adapters, type: :array
        attribute :dvd_drives, type: :array
        attribute :hard_drives, type: :array

        lazy_attributes :network_adapters,
                        :dvd_drives,
                        :hard_drives,
                        :floppy_drive

        %i(floppy_drive).each do |attr|
          define_method attr do
            return nil unless generation == 1
            attributes[attr] = nil \
              if attributes[attr].is_a?(String)
            attributes[attr] = service.send("#{attr}s".to_sym).model.new(attributes[attr]) if attributes[attr].is_a?(Hash)
            attributes[attr] ||= service.send("#{attr}s".to_sym, vm: self).first
          end
        end

        %i(network_adapters dvd_drives hard_drives vhds).each do |attr|
          define_method attr do
            attributes[attr] = nil \
              if !attributes[attr].is_a?(Array) ||
                 attributes[attr].any? { |v| v.is_a?(String) } ||
                 attributes[attr].empty?
            attributes[attr] ||= service.send(attr, vm: self)
          end
        end

        def bios
          bios_wrapper
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
          puts "Saving server with; #{attributes}, #{options}"

          data = \
          if !persisted?
            # Name, MemoryStartupBytes, BootDevice(?), SwitchName, Generation, VHD(NoVHD/Path)
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

              processor_count: changed?(:processor_count) && processor_count,
              dynamic_memory: changed?(:dynamic_memory_enabled) && dynamic_memory_enabled,
              static_memory: changed?(:dynamic_memory_enabled) && !dynamic_memory_enabled,
              memory_minimum_bytes: changed?(:memory_minimum) && dynamic_memory_enabled && memory_minimum,
              memory_maximum_bytes: changed?(:memory_maximum) && dynamic_memory_enabled && memory_maximum,
              memory_startup_bytes: changed?(:memory_startup) && memory_startup,
              notes: changed?(:notes) && notes,
              new_name: changed?(:name) && name,

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
          state == 2
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

        private

        def bios_wrapper
          if generation == 1
            @bios ||= Fog::Compute::Hyperv::Bios.new(service.get_vm_bios(computer_name: computer_name, vm_name: name).merge service: service)
          elsif generation == 2
            @bios ||= Fog::Compute::Hyperv::Firmware.new(service.get_vm_firmware(computer_name: computer_name, vm_name: name).merge service: service)
          end
        end
      end
    end
  end
end
