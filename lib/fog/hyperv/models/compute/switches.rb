module Fog
  module Compute
    class Hyperv
      class Switches < Fog::Hyperv::Collection
        model Fog::Compute::Hyperv::Switch

        get_method :get_vm_switch

        def get(name, filters = {})
          super filters.merge(name: name)
        end
      end
    end
  end
end
