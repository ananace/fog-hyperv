# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def set_vm_network_adapter(id:, computer_name: nil, **options)
      requires_one options, :vm_id, :management_os
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
      cmdlist << ['$NIC | Set-VMNetworkAdapter', { passthru: true, **options }]

      run_cmdlist(cmdlist, target_computer: computer_name)
    end
  end
end
