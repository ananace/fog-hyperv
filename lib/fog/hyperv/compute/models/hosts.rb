# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/host'

module Fog
  module Hyperv
    class Compute
      class Hosts < Fog::Hyperv::Collection
        model Fog::Hyperv::Compute::Host

        get_method :get_vm_host

        def get(name, filters = {})
          super(filters.merge(computer_name: name))
        end
      end
    end
  end
end
