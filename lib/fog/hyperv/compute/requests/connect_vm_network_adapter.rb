# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def connect_vm_network_adapter(id:, computer_name: nil, **options)
      requires_one options, :vm_id, :management_os
      requires_one options, :switch_name, :switch_id
      options.delete :management_os

      cmdlist = []
      if options[:vm_id]
        vm_id = options.delete :vm_id
        cmdlist += [
          ['$VM = Get-VM', { id: vm_id }],
          ['$NIC = $VM | Get-VMNetworkAdapter', { _by_id: id }]
        ]
      else
        options.delete :vm_id
        cmdlist << ['$NIC = Get-VMNetworkAdapter', { _by_id: id, management_os: true }]
      end
      if options[:switch_id]
        switch_id = options.delete :switch_id
        options.delete :switch_name
        cmdlist += [
          ['$Switch = Get-VMSwitch', { id: switch_id }],
          ['$NIC | Connect-VMNetworkAdapter -VMSwitch @Switch', options]
        ]
      else
        switch_name = options.delete :switch_name
        options.delete :switch_id
        cmdlist << ['$NIC | Connect-VMNetworkAdapter', { switch_name:, **options }]
      end

      run_cmdlist(cmdlist, skip_json: true, target_computer: computer_name)
    end
  end

  class Mock
    def connect_vm_network_adapter(*args); end
  end
end
