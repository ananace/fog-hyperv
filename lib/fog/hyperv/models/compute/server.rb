require 'fog/compute/models/server'

module Fog
  module Compute
    class Hyperv
      class Server < Fog::Compute::Server
        identity :id

        attribute :name
        attribute :computer_name
        attribute :state
        attribute :status
        attribute :memory_assigned
        attribute :processor_count

        # attribute :network_adapters
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

        def reboot(options = {})
          requires :name, :computer_name
          service.restart_vm options.merge(
            name: self.name,
            computer_name: self.computer_name
          )
        end

        private

        def initialize_network_adapters
          self.attributes[:network_adapters].map! { |nic| nic.is_a?(Hash) ? service.interfaces.new(nic) : nic } \
            if attributes[:network_adapters] && attributes[:network_adapters].is_a?(Array)
        end

        def initialize_hard_drives
          self.attributes[:hard_drives].map! { |hd| hd.is_a?(Hash) ? service.volumes.new(hd) : hd } \
            if attributes[:hard_drives] && attributes[:hard_drives].is_a?(Array)
        end
      end
    end
  end
end
