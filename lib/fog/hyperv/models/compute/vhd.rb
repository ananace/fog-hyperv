module Fog
  module Compute
    class Hyperv
      class Vhd < Fog::Hyperv::Model
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
        attribute :size, type: :integer, default: 687_194_767_36
        attribute :vhd_format
        attribute :vhd_type
        # TODO? VM Snapshots?
        #

        # def identity_name
        #   :disk_identifier unless disk_identifier
        #   :disk_number if disk
        #   :path
        # end

        def real_path
          requires :path

          ret = path
          ret += '.vhdx' unless ret.downcase.end_with? '.vhdx'
          ret = host.virtual_hard_disk_path + '\\' + ret unless ret.downcase.start_with? host.virtual_hard_disk_path.downcase
          ret
        end

        def host
          requires :computer_name

          @host ||= begin
            ret = parent
            ret = service.hosts.get computer_name unless ret
            ret = ret.parent unless ret.is_a?(Host)
            ret
          end
        end

        def save
          requires :path, :computer_name, :size

          data = \
            if persisted?
              # Can't change much of a VHD
              attributes
            else
              service.new_vhd(
                computer_name: computer_name,
                path: real_path,

                block_size_bytes: block_size,
                size_bytes: size,

                _return_fields: self.class.attributes,
                _json_depth: 1
              )
            end

          merge_attributes(data)
          @old = dup
          self
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

        def destroy
          requires :path, :disk_identifier
          # TODO: Other computers in a cluster?

          service.remove_item(
            path: path
          ) if path
        end
      end
    end
  end
end
