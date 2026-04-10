# frozen_string_literal: true

require 'fog/hyperv/collection'
require 'fog/hyperv/compute/models/server'

module Fog
  module Hyperv
    class Compute
      class Servers < Fog::Hyperv::ComputerCollection
        model Fog::Hyperv::Compute::Server

        get_method :get_vm

        def get(identity, filters = {})
          guid = identity =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/

          search = {}
          search[:id] = identity if guid
          search[:name] = identity unless guid

          super(search.merge(filters))
        end
      end
    end
  end
end
