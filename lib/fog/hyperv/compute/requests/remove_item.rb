# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def remove_item(path:, computer_name: nil, **options)
      # TODO: Really lock this method down, validation is good.
      run_cmd 'Remove-Item', _target_computer: computer_name, _skip_json: true, path:, force: true, **options
    end
  end
end
