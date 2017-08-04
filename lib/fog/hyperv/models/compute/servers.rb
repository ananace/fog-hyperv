module Fog
  module Compute
    class Hyperv
      class Servers < Fog::Collection
        autoload :Server, File.expand_path('../server', __FILE__)

        model Fog::Compute::Hyperv::Server

        def all(filters = {})
          load service.get_vm(filters)
        end

        def get(id, computer = '.')
          new service.get_vm(id: id, computer_name: computer)
        end
      end
    end
  end
end
