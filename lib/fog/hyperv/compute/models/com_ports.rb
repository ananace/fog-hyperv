# frozen_string_literal: true

class Fog::Hyperv::Compute
  class ComPorts < Fog::Hyperv::Collection
    model Fog::Hyperv::Compute::ComPort

    get_method :get_vm_com_port

    attribute :computer_name
    attribute :vm_id

    requires :vm_id

    def get(id, **filters)
      super(_by_id: id, **filters)
    end
  end
end
