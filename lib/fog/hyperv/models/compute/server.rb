require 'fog/compute/models/server'

module Fog
  module Compute
    class Hyperv
      class Server < Fog::Compute::Server
        identity :id

        attribute :name
        attribute :computer_name
        attribute :dynamic_memory_enabled
        attribute :generation # 1 => bios, 2 => uefi
        attribute :state
        attribute :status
        attribute :memory_assigned
        attribute :memory_maximum
        attribute :memory_minimum
        attribute :memory_startup
        attribute :note
        attribute :processor_count

        attribute :network_adapters
        attribute :dvd_drives
        attribute :floppy_drive
        attribute :hard_drives

        def initialize(attributes = {})
          super attributes

          initialize_network_adapters
          initialize_hard_drives
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

          service.new_vm options.merge(attributes)
        end

        def ready?
          state == 2
        end

        def network_adapters
          attributes[:network_adapters] ||= service.network_adapters(computer_name: computer_name, vm_name: name)
        end

        def hard_drives
          attributes[:hard_drives] ||= service.hard_drives(computer_name: computer_name, vm_name: name)
        end

        def mac_addresses
          network_adapters.map { |nic| nic.mac_address }
        end

        private

        def initialize_network_adapters
          return unless network_adapters.is_a?(Array) &&
                        !network_adapters.empty?

          if network_adapters.first.is_a? String
            attributes[:network_adapters] = nil
          else
            attributes[:network_adapters].map! do |nic|
              nic.is_a?(Hash) ? service.network_adapters.new(nic) : nic
            end
          end
        end

        def initialize_hard_drives
          return unless hard_drives.is_a?(Array) &&
                        !hard_drives.empty?

          if hard_drives.first.is_a? String
            attributes[:hard_drives] = nil
          else
            attributes[:hard_drives].map! do |hd|
              hd.is_a?(Hash) ? service.hard_drives.new(hd) : hd
            end
          end
        end
      end
    end
  end
end
