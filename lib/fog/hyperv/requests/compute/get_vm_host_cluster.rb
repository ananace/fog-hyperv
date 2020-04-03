# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_host_cluster(options = {})
          requires_version '10.0'
          requires options, :cluster_name

          run_shell('Get-VMHostCluster', options)
        end
      end

      class Mock
        def get_vm_host_cluster(options = {})
          requires_version '10.0'
          requires options, :cluster_name

          # TODO
          Fog::Mock.not_implemented
        end
      end
    end
  end
end

