module Fog
  module Compute
    class Hyperv
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

        def self.ensure_collections!
          return if @collections
          @collections = true

          Fog::Compute::Hyperv.collections.each do |coll|
            coll_name = coll.to_s.split('_').map(&:capitalize).join
            klass = Fog::Compute::Hyperv.const_get(coll_name)
            next if klass.requires? :vm

            define_method coll do
              @collections[coll] ||= service.send(coll, computer: self)
            end
          end
        end
      end
    end
  end
end
