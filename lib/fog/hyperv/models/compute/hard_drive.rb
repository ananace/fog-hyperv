module Fog
  module Compute
    class Hyperv
      class HardDrive < Fog::Model
        identity :id

        attribute :computer_name
        attribute :disk
        attribute :is_deleted
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :controller_location
        attribute :controller_number
        attribute :controller_type
        attribute :vm_id
        attribute :vm_name
        # TODO? VM Snapshots?

      end
    end
  end
end
