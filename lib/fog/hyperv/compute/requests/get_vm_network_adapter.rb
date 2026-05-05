# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_network_adapter(computer_name: nil, **options)
      requires_one options, :vm_id, :all, :management_os

      id = options.delete :id
      if options[:vm_id]
        vm_id = options.delete :vm_id
        options.delete :management_os
        options.delete :all
        run_cmdlist(
          [
            ['$VM = Get-VM', { id: vm_id }],
            ['$VM | Get-VMNetworkAdapter', { _by_id: id, **options }]
          ],
          target_computer: computer_name
        )
      else
        options.delete :management_os if options[:all]
        run_cmd 'Get-VMNetworkAdapter', _by_id: id, _target_computer: computer_name, **options
      end
    end
  end

  class Mock
    def get_vm_network_adapter(**args)
      requires_one args, :vm_name, :all, :management_os

      data = handle_mock_response(args)
      if args[:all]
        data
      elsif args[:vm_name]
        data.find { |i| i[:vm_name].casecmp(args[:vm_name]).zero? }
      elsif args[:management_os]
        data.find { |i| i[:is_management_os] }
      end
    end
  end
end
