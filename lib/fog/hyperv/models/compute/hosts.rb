module Fog
  module Compute
    class Hyperv
      class Hosts < Fog::Hyperv::Collection
        model Fog::Compute::Hyperv::Host

        get_method :get_vm_host

        def get(name, filters = {})
          super filters.merge(computer_name: name)
        end
      end
    end
  end
end
