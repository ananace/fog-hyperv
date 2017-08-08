require 'fog/compute/models/server'

module Fog
  module Compute
    class Hyperv
      class Server < Fog::Compute::Server
        identity :id

        attribute :name
        attribute :computer_name
        attribute :dynamic_memory_enabled
        attribute :floppy_drive
        attribute :generation # 1 => bios, 2 => uefi
        attribute :state
        attribute :status
        attribute :memory_assigned
        attribute :memory_maximum
        attribute :memory_minimum
        attribute :memory_startup
        attribute :notes
        attribute :processor_count

        attribute :network_adapters
        attribute :dvd_drives
        attribute :hard_drives

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

        def start(options = {})
          requires :name, :computer_name
          service.start_vm options.merge(
            name: self.name,
            computer_name: self.computer_name
          )
        end

        def stop(options = {})
          requires :name, :computer_name
          service.stop_vm options.merge(
            name: self.name,
            computer_name: self.computer_name
          )
        end

        def restart(options = {})
          requires :name, :computer_name
          service.restart_vm options.merge(
            name: self.name,
            computer_name: self.computer_name
          )
        end

        def destroy(options = {})
          requires :name, :computer_name
          if ready?
            stop(options)
            wait_for { !ready? }
          end
          service.remove_vm options.merge(
            name: name,
            computer_name: computer_name
          )
        end

        def save(options = {})
          requires :name

          data = if persisted?
                   service.set_vm options.merge(
                     computer_name: computer_name,
                     name: name,
                     processor_count: processor_count,
                     dynamic_memory: dynamic_memory_enabled,
                     static_memory: !dynamic_memory_enabled,
                     memory_minimum_bytes: dynamic_memory_enabled && memory_minimum,
                     memory_maximum_bytes: dynamic_memory_enabled && memory_maximum,
                     memory_startup_bytes: memory_startup,
                     notes: notes,
                     passthru: true,
                     _return_fields: self.class.attributes,
                     _json_depth: 1
                   )
                 else
                   # Name, MemoryStartupBytes, BootDevice(?), SwitchName, Generation, VHD(NoVHD/Path)
                   service.new_vm options.merge(attributes.merge(options))
                 end
          merge_attributes(data)
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
      end
    end
  end
end
