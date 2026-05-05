# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def new_vhd(path:, size_bytes:, computer_name: nil, **options)
      run_cmd 'New-VHD', _target_computer: computer_name, path:, size_bytes:, **options
    end
  end
end
