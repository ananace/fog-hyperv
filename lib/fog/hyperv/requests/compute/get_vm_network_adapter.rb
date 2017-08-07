module Fog
  module Compute
    class Hyperv
      class Real
        def get_vm_network_adapter(options = {})
          # TODO: Would work better with getting the VM object by UUID instead
          name = options.delete(:vm_name) || options.delete(:name)
          run_shell('Get-VMNetworkAdapter', options.merge(vm_name: name))
        end
      end
    end
  end
end
