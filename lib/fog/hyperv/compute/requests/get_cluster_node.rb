# frozen_string_literal: true

module Fog
  module Hyperv
    class Compute
      class Real
        def get_cluster_node(**options)
          run_shell('Get-ClusterNode', **options)
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
  end
end
