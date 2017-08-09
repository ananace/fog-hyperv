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
        attribute :dynamic_memory_enabled
        attribute :floppy_drive
        attribute :generation, type: :integer # 1 => bios, 2 => uefi
        attribute :state
        attribute :status
        attribute :memory_assigned
        attribute :memory_maximum
        attribute :memory_minimum
        attribute :memory_startup
        attribute :notes
        attribute :processor_count

        attribute :network_adapters, type: :array
        attribute :dvd_drives, type: :array
        attribute :hard_drives, type: :array

        lazy_attributes :network_adapters,
                        :dvd_drives,
                        :hard_drives,
                        :floppy_drive

        %i(floppy_drive).each do |attr|
          define_method attr do
            attributes[attr] = nil \
              if attributes[attr] == '' || (attributes[attr].is_a?(String) && attributes[attr].start_with?('Microsoft.HyperV'))
            attributes[attr] = service.send("#{attr}s".to_sym).model.new(attributes[attr]) if attributes[attr].is_a?(Hash)
            attributes[attr] ||= service.send("#{attr}s".to_sym, computer_name: computer_name, vm_name: name).first
          end
        end

        %i(network_adapters dvd_drives hard_drives).each do |attr|
          define_method attr do
            attributes[attr] = [] \
              if attributes[attr] == ''
            attributes[attr] = nil \
              if !attributes[attr].is_a?(Array) ||
                 attributes[attr].any? { |v| v.is_a?(String) && v.start_with?('Microsoft.HyperV') }
            attributes[attr] ||= service.send(attr, computer_name: computer_name, vm_name: name)
          end
        end
        alias interfaces :network_adapters
        alias volumes :hard_drives

        def bios
          bios_wrapper
        end
        alias firmware :bios

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
          stop(options.merge(as_job: true)) if ready?
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

          # TODO: Do this in two steps for newly created VMs
          if persisted?
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
          else
            # Name, MemoryStartupBytes, BootDevice(?), SwitchName, Generation, VHD(NoVHD/Path)
            usable = %i(name memory_startup generation).freeze
            service.new_vm \
              attributes.select { |k, _v| usable.include? k }.merge(options)
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
