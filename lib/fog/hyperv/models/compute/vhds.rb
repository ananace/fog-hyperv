module Fog
  module Compute
    class Hyperv
      class Vhds < Fog::Hyperv::VMCollection
        model Fog::Compute::Hyperv::Vhd
        match_on :vm_id

        get_method :get_vhd

        def get(path, filters = {})
          super search_attributes.merge(filters.merge(path: path))
        end
      end
    end
  end
end
