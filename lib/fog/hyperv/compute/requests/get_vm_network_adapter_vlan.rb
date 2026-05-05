# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def get_vm_network_adapter_vlan(id:, computer_name: nil, **options)
      requires_one options, :vm_id, :management_os

      commands = []
      if options.key? :vm_id
        vm_id = options.delete :vm_id
        options.delete :management_os
        commands += [
          ['$VM = Get-VM', { id: vm_id }],
          ['$NIC = $VM | Get-VMNetworkAdapter', { _by_id: id }]
        ]
      else
        options.delete :management_os
        commands << ['$NIC = Get-VMNetworkAdapter', { management_os: true, _by_id: id }]
      end
      commands << ['$NIC | Get-VMNetworkAdapterVlan', options]

      run_cmdlist(
        commands,
        target_computer: computer_name
      )
    end
  end

  class Mock
    def get_vm_network_adapter_vlan(**args)
      data = handle_mock_response(args)
      if args[:vm_id]
        data.find { |i| i[:vm_id].casecmp(args[:vm_id]).zero? }
      elsif args[:management_os]
        data.find { |i| i[:is_management_os] }
      else
        data
      end
    end
  end
end
