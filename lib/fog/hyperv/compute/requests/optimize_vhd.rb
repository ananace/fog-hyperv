# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def optimize_vhd(path:, computer_name: nil, **options)
      run_cmd 'Optimize-VHD', _target_computer: computer_name, _skip_json: true, path: path, **options
    end
  end
end
