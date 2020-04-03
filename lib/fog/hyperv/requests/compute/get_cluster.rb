# frozen_string_literal: true

module Fog
  module Compute
    class Hyperv
      class Real
        def get_cluster(options = {})
          run_shell('Get-Cluster', options)
        end
      end
    end
  end
end
