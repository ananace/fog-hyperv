module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_host_cluster(options = {})
          requires options, :cluster_name
          run_shell('Get-VMHostCluster', options)
        end
      end
    end
  end
end

