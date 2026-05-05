# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_group(computer_name: nil, **options)
      requires_version '10.0'

      run_cmd('Get-VMGroup', _target_computer: computer_name, **options)
    end
  end

  class Mock
    def get_vm_group(**_options)
      requires_version '10.0'

      # TODO
      Fog::Mock.not_implemented
    end
  end
end
