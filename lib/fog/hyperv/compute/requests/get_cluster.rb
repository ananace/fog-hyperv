# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_cluster(**options)
      _by_id = options.delete(:id)

      run_cmd 'Get-Cluster', _by_id:, **options
    end
  end
end
