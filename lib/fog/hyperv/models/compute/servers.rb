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
            cluster: cluster
          }.merge filters)
        end

        def get(id, computer = nil)
          computer = computer_name if !computer && computer_name
          new service.get_vm(id: id, computer_name: computer)
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
