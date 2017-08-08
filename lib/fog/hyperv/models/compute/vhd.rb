module Fog
  module Compute
    class Hyperv
      class VHD < Fog::Model
        identity :disk_identifier

        attribute :attached
        attribute :block_size
        attribute :computer_name
        attribute :disk
        attribute :file_size
        attribute :is_deleted
        attribute :minimum_size
        attribute :name
        attribute :path
        attribute :pool_name
        attribute :size
        attribute :vhd_format
        attribute :vhd_type
        # TODO? VM Snapshots?
        #

        def identity_name
          :path if path
          :disk_number if disk
        end

        def disk_number
          disk.number if disk
        end

        def disk_number=(num)
          disk.number = num if disk
        end

        def reload
          data = service.get_vhd(
            computer_name: computer_name,
            path: path,
            disk_number: disk_number
          )
          merge_attributes(data.attributes)
          self
        end
      end
    end
  end
end
