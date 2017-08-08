module Fog
  module Compute
    class Hyperv
      class Servers < Fog::Collection
        autoload :Server, File.expand_path('../server', __FILE__)

        attr_accessor :computer_name
        attr_accessor :cluster

        model Fog::Compute::Hyperv::Server

        def all(filters = {})
          load service.get_vm({
            computer_name: computer_name,
            cluster: cluster,
            _return_fields: model.attributes,
            _json_depth: 1
          }.merge filters)
        end

        def get(identity, computer = nil)
          guid = identity =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/

          search = {
            computer_name: computer || computer_name,
            _return_fields: model.attributes,
            _json_depth: 1
          }
          search[:id] = identity if guid
          search[:name] = identity unless guid

          new service.get_vm(search)
        end

        def new(options = {})
          super({
            computer_name: computer_name,
            cluster: cluster
          }.merge(options))
        end
      end
    end
  end
end
