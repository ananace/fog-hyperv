# frozen_string_literal: true

require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      # A VM hard drive - VHD - file
      class Vhd < Fog::Hyperv::Model
        # rubocop:disable Layout/HashAlignment

        # VHD types
        # @note Defined by Microsoft.Vhd.PowerShell.VhdType
        VHD_TYPE_ENUM_VALUES = {
          Unknown:      0,
          Fixed:        2,
          Dynamic:      3,
          Differencing: 4
        }.freeze

        # VHD formats
        # @note Defined by Microsoft.Vhd.PowerShell.VhdFormat
        VHD_FORMAT_ENUM_VALUES = {
          Unknown: 0,
          VHD:     2,
          VHDX:    3,
          VHDSet:  4
        }.freeze
        # rubocop:enable Layout/HashAlignment

        # @!attribute [r] disk_identifier
        #   @return [String] the GUID of this VHD
        identity :disk_identifier

        attribute :computer_name

        # @!attribute [r] attached
        #   @return [Boolean] is the VHD attached to something
        attribute :attached, type: :boolean
        # @!attribute [r] block_size
        #   @return [Integer] the block size of the VHD in bytes
        attribute :block_size, type: :integer
        # @!attribute [r] disk
        #   @return [String] the disk number
        attribute :disk, type: :integer
        # @!attribute [r] file_size
        #   @return [Integer] the size of the VHD file in bytes
        attribute :file_size, type: :integer
        # @!attribute [r] is_deleted
        #   @return [Boolean] is the VHD deleted
        attribute :is_deleted, type: :boolean
        # @!attribute [r] minimum_size
        #   @return [Integer] the minimum size of the VHD in bytes
        attribute :minimum_size, type: :integer
        # @!attribute [r] path
        #   @return [String] the file path for the VHD, without extension
        attribute :path, type: :string, default: 'New Disk'
        # @!attribute [r] pool_name
        #   @return [String] the name of the pool storing this VHD
        attribute :pool_name
        # @!attribute [r] size
        #   @return [Integer] the size of the VHD in bytes
        attribute :size, type: :integer, default: 343_597_383_68
        # @!attribute [r] vhd_format
        #   @return [:Unknown, :VHD, :VHDX, :VHDSet] the format of the VHD
        #   @see VHD_FORMAT_ENUM_VALUES
        attribute :vhd_format, type: :enum, default: :VHDX, values: VHD_FORMAT_ENUM_VALUES
        # @!attribute [r] vhd_type
        #   @return [:Unknown, :Fixed, :Dynamic, :Differencing] the type of the VHD
        #   @see VHD_TYPE_ENUM_VALUES
        attribute :vhd_type, type: :enum, default: :Dynamic, values: VHD_TYPE_ENUM_VALUES
        # TODO? VM Snapshots?
        #

        # def identity_name
        #   :disk_identifier unless disk_identifier
        #   :disk_number if disk
        #   :path
        # end

        # @!attribute [r] real_path
        # @return [String] the real path on disk for the VHD file
        def real_path
          requires :path, :computer_name

          basepath = "#{host.virtual_hard_disk_path}\\"

          ret = path
          ext = vhd_format&.downcase || 'vhdx'
          ret += ".#{ext}" unless ret.downcase.end_with? ".#{ext}"
          ret = basepath + ret unless ret.downcase.start_with? basepath.downcase
          ret
        end

        # @!attribute [r] unc_path
        # @return [String] the UNC path for the VHD file in a cluster
        def unc_path
          "\\\\#{computer_name || '.'}\\#{real_path.tr ':', '$'}"
        end

        # @!attribute [r] host
        # @return [Host] the host that stores this VHD
        def host
          requires :computer_name

          @host ||= begin
            ret = parent || service.hosts.get(computer_name)
            ret = ret.parent unless ret.is_a?(Host)
            ret
          end
        end

        # Save the VHD to Hyper-V
        def save
          # Can't change much of a VHD
          return self if persisted?

          requires :path, :computer_name, :size

          data = service.new_vhd(
            computer_name: computer_name,
            path: real_path,

            block_size_bytes: block_size,
            size_bytes: size,

            _return_fields: self.class.attributes,
            _json_depth: 1
          )

          merge_attributes(data)
          @old = dup
          self
        end

        # Reload the VHD attributes from Hyper-V
        def reload
          requires :computer_name
          requires_one :path, :disk

          data = service.get_vhd(
            computer_name: computer_name,
            path: path,
            disk_number: disk
          )
          merge_attributes(data.attributes)
          @old = data
          self
        end

        # Remove the VHD from disk
        def destroy
          requires :path, :disk_identifier

          service.remove_item(
            path: unc_path
          )
        end
      end
    end
  end
end
