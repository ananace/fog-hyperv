# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Real
    def add_vm_network_adapter(computer_name: nil, **options)
      requires_one options, :vm_id, :management_os
      options.delete :management_os

      if options[:vm_id]
        vm_id = options.delete :vm_id
        run_cmdlist(
          [
            ['$VM = Get-VM', { id: vm_id }],
            ['$VM | Add-VMNetworkAdapter', { _always_include: %i[is_legacy], passthru: true, **options }]
          ],
          target_computer: computer_name
        )
      else
        options.delete :vm_id
        run_cmd('Add-VMNetworkAdapter', _target_computer: computer_name, management_os: true, passthru: true, **options)
      end
    end
  end
end
