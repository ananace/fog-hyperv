module Fog
  module Compute
    class Hyperv
      class Interfaces < Fog::Collection
        autoload :Interface, File.expand_path('../interface', __FILE__)

        attr_accessor :computer_name
        attr_accessor :vm_name

        model Fog::Compute::Hyperv::Interface

        def all(filters = {})
          load service.get_vm_network_adapter({
            computer_name: computer_name,
            vm_name: vm_name
          }.merge(filters))
        end

        def get(name, filters = {})
          new service.get_vm_network_adapter({
            computer_name: computer_name,
            vm_name: id,
            name: name
          }.merge(filters))
        end

        def new(options = {})
          super({
            computer_name: computer_name,
            vm_name: vm_name
          }.merge(options))
        end
      end
    end
  end
end
