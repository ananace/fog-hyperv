# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm(**options)
      run_cmd('Get-VM', **options)
    end
  end

  class Mock
    def get_vm(**args)
      data = handle_mock_response(**args)
      data = data.find { |v| v[:name].casecmp(args[:name]).zero? } if args[:name]
      data = data.find { |v| v[:id].casecmp(args[:id]).zero? } if args[:id]
      data
    end
  end
end
