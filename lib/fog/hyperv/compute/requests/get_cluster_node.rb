# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_cluster_node(id:, **options)
      run_cmdlist(
        [
          ['$Cluster = Get-Cluster', { _by_id: id }],
          ['$Cluster | Get-ClusterNode', options]
        ]
      )
    end
  end

  class Mock
    def get_cluster_node(**args)
      data = handle_mock_response args
      data = data.find { |n| n[:name] == args[:name] } if args[:name]
      data
    end
  end
end
