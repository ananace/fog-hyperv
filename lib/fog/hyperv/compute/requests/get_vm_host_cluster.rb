# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_host_cluster(cluster_name:, computer_name: nil, **options)
      requires_version '10.0'

      run_cmd 'Get-VMHostCluster', _target_computer: computer_name, cluster_name: cluster_name, **options
    end
  end

  class Mock
    def get_vm_host_cluster(**options)
      requires_version '10.0'
      requires options, :cluster_name

      # TODO
      Fog::Mock.not_implemented
    end
  end
end
