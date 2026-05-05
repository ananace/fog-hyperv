# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def resize_vhd(path:, size_bytes:, computer_name: nil, **options)
      run_cmd 'Resize-VHD', _target_computer: computer_name, _skip_json: true, path:, size_bytes:, **options
    end
  end
end
