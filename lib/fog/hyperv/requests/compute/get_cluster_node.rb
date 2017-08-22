module Fog
  module Compute
    class Hyperv
      class Real
        def get_cluster_node(options = {})
          run_shell('Get-ClusterNode', options)
        end
      end
    end
  end
end
