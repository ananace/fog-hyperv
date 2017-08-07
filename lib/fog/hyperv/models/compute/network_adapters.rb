module Fog
  module Compute
    class Hyperv
      class NetworkAdapters < Fog::Collection
        autoload :NetworkAdapter, File.expand_path('../network_adapter', __FILE__)

        attr_accessor :computer_name
        attr_accessor :vm_name

        model Fog::Compute::Hyperv::NetworkAdapter

        def all(filters = {})
          load [service.get_vm_network_adapter({
            computer_name: computer_name,
            vm_name: vm_name,
            _json_depth: 1
          }.merge(filters))].flatten
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
