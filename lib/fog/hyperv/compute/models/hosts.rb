# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Hosts < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::Host

    get_method :get_vm_host

    def get(name, **filters)
      super(computer_name: name, **filters)
    end
  end
end
