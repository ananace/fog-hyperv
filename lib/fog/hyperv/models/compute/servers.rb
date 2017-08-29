module Fog
  module Compute
    class Hyperv
      class Servers < Fog::Hyperv::ComputerCollection
        model Fog::Compute::Hyperv::Server

        get_method :get_vm

        def get(identity, filters = {})
          guid = identity =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/

          search = {}
          search[:id] = identity if guid
          search[:name] = identity unless guid

          super search.merge(filters)
        end
      end
    end
  end
end
