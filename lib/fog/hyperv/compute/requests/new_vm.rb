# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def new_vm(computer_name: nil, **options)
      requires options, :new_vhd_path, :new_vhd_size_bytes \
        if options[:new_whd_path] || options[:new_vhd_size_bytes]

      run_cmd 'New-VM', _target_computer: computer_name, **options
    end
  end
end
