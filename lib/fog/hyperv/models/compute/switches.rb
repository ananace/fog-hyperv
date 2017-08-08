module Fog
  module Compute
    class Hyperv
      class Switches < Fog::Collection
        autoload :Switch, File.expand_path('../switch', __FILE__)

        attr_accessor :computer_name

        model Fog::Compute::Hyperv::Switch

        def all(filters = {})
          load [service.get_vm_switch({
            computer_name: computer_name,
            _return_fields: model.attributes,
            _json_depth: 1
          }.merge(filters))].flatten
        end

        def get(name, filters = {})
          new service.get_vm_switch({
            computer_name: computer_name,
            name: name,
            _return_fields: model.attributes,
            _json_depth: 1
          }.merge(filters))
        end

        def new(options = {})
          super({
            computer_name: computer_name
          }.merge(options))
        end
      end
    end
  end
end
