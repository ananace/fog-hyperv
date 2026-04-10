# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class Host < Fog::Hyperv::Model
        identity :name

        attribute :computer_name
        attribute :fully_qualified_domain_name
        attribute :logical_processor_count
        attribute :memory_capacity
        attribute :mac_address_minimum
        attribute :mac_address_maximum
        attribute :maximum_storage_migrations
        attribute :maximum_virtual_machine_migrations
        attribute :virtual_hard_disk_path
        attribute :virtual_machine_path

        def initialize(attrs = {})
          super

          @collections = {}
          self.class.ensure_collections!
        end

        def secure_boot_templates
          @secure_boot_templates ||= service.get_vm_host_sbt(computer_name: computer_name)
        end

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
