# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class Host < Fog::Hyperv::Model
        # @!attribute [r] name
        #   @return [String] the name of the host
        identity :name

        # @!attribute [r] computer_name
        #   @return [String] the name of the computer that this host refers to
        attribute :computer_name

        # @!attribute [r] fully_qualified_domain_name
        #   @return [String] the FQDN of this host
        attribute :fully_qualified_domain_name
        # @!attribute [r] logical_processor_count
        #   @return [Integer] the number of logical CPUs on this host
        attribute :logical_processor_count, type: :integer
        # @!attribute [r] memory_capacity
        #   @return [Integer] the amount of memory on this host
        attribute :memory_capacity, type: :integer
        # @!attribute [r] mac_address_minimum
        #   @return [String] the lowest possible MAC address for VMs on this host
        attribute :mac_address_minimum
        # @!attribute [r] mac_address_maximum
        #   @return [String] the highest possible MAC address for VMs on this host
        attribute :mac_address_maximum
        # @!attribute [r] maximum_storage_migrations
        #   @return [String] the maximum number of simulatenous storage migrations on this host
        attribute :maximum_storage_migrations, type: :integer
        # @!attribute [r] maximum_virtual_machine_migrations
        #   @return [String] the maximum number of simulatenous VMM migrations on this host
        attribute :maximum_virtual_machine_migrations, type: :integer
        # @!attribute [r] virtual_hard_disk_path
        #   @return [String] the path where VHDs will be stored on this host
        attribute :virtual_hard_disk_path
        # @!attribute [r] virtual_machine_path
        #   @return [String] the path where VMs will be stored on this host
        attribute :virtual_machine_path

        def initialize(attrs = {})
          super

          @collections = {}
          self.class.ensure_collections!
        end

        # @!attribute [r] secure_boot_templates
        # @return [Array<String>] the available secure boot templates on this host
        def secure_boot_templates
          @secure_boot_templates ||= service.get_vm_host_sbt(computer_name: computer_name)
        end

        # @!visibility private
        def self.ensure_collections!
          return if @collections

          @collections = true
          Fog::Hyperv::Compute.collections.each do |coll|
            # Hosts don't have host collections
            next if coll == :hosts

            coll_name = coll.to_s.split('_').map(&:capitalize).join
            klass = Fog::Hyperv::Compute.const_get(coll_name)
            next if klass.requires?(:vm)

            define_method coll do
              @collections[coll] ||= service.send(coll, computer: self)
            end
          end
        end
      end
    end
  end
end
