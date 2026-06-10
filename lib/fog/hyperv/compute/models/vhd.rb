# frozen_string_literal: true

class Fog::Hyperv::Compute
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
    #   @return [String] the guid of this VHD
    identity :disk_identifier

    # @!attribute [r] computer_name
    #   @return [String] the name of the computer hosting this VHD
    attribute :computer_name

    # @!attribute [r] attached
    #   @return [Boolean] is the VHD attached to something
    attribute :attached, type: :boolean
    # @!attribute [r] block_size
    #   @return [Integer] the block size of the VHD in bytes
    attribute :block_size, type: :integer
    # @!attribute [r] disk_number
    #   @return [Integer,nil] the disk number
    attribute :disk_number
    # @!attribute [r] file_size
    #   @return [Integer,nil] the size of the VHD file in bytes
    attribute :file_size
    # @!attribute [r] logical_sector_size
    #   @return [512, 4096] the logical sector size for the VHD in bytes
    attribute :logical_sector_size, type: :integer
    # @!attribute [r] minimum_size
    #   @return [Integer,nil] the minimum possible size of the VHD in bytes, for shrinking purposes
    attribute :minimum_size
    # @!attribute [r] parent_path
    #   @return [String,nil] the path to the parent VHD
    attribute :parent_path
    # @!attribute [r] path
    #   @return [String,nil] the path to the VHD on disk
    attribute :path
    # @!attribute [r] pool_name
    #   @return [String] the name of the pool storing this VHD
    attribute :pool_name
    # @!attribute physical_sector_size_bytes
    #   @return [512, 4096] the physical sector size for the VHD in bytes
    attribute :physical_sector_size, type: :integer
    # @!attribute size
    #   @return [Integer,nil] the size of the VHD in bytes
    #   @note Defaults to 32GB if not specified
    attribute :size, default: 32 * 1024 * 1024 * 1024
    # @!attribute [r] vhd_format
    #   @return [:Unknown, :VHD, :VHDX, :VHDSet] the format of the VHD
    #   @see VHD_FORMAT_ENUM_VALUES
    attribute :vhd_format, type: :hypervenum, default: :VHDX, values: VHD_FORMAT_ENUM_VALUES
    # @!attribute [r] vhd_type
    #   @return [:Unknown, :Fixed, :Dynamic, :Differencing] the type of the VHD
    #   @see VHD_TYPE_ENUM_VALUES
    attribute :vhd_type, type: :hypervenum, default: :Dynamic, values: VHD_TYPE_ENUM_VALUES

    # @!attribute [r] basename
    #   @return [String] the basename of the VHD file, without extension
    attribute :basename

    # @!attribute [r] unc_path
    # @return [String] the UNC path to the VHD file in a cluster
    def unc_path
      requires :path

      "\\\\#{computer_name || 'localhost'}\\#{path.tr ':', '$'}"
    end

    # Save the VHD to Hyper-V
    def create
      if basename
        requires :vm

        attributes[:path] ||= vm.build_vhd_path("#{basename}.#{vhd_ext}")
      end

      requires_one :path, :disk_number

      attrs = {
        source_disk: disk_number,
        logical_sector_size_bytes: logical_sector_size,
        physical_sector_size_bytes: physical_sector_size
      }.compact
      case vhd_type
      when :Dynamic
        attrs[:dynamic] = true
        requires :size unless disk_number
      when :Differencing
        requires :parent_path
        attrs[:differencing] = true
        attrs[:parent_path] = parent_path
        attrs.delete :source_disk
        attrs.delete :logical_sector_size_bytes
      when :Fixed
        attrs[:fixed] = true
        requires :size unless disk_number
      else
        raise "Invalid VHD type #{vhd_type.inspect}, must be :Dynamic, :Fixed, or :Differencing"
      end

      merge_attributes(
        service.new_vhd(
          computer_name: computer_name,

          path: path,
          block_size_bytes: block_size,
          size_bytes: size,
          **attrs,

          _return_fields: self.class.attributes - %i[basename]
        )
      )
    end

    def update
      requires :path

      return self unless changed?(:size)

      service.resize_vhd(
        computer_name: old.computer_name,
        path: old.path,

        size_bytes: size
      )
      @old.size = size

      self
    end

    # Reload the VHD attributes from Hyper-V
    def reload
      requires_one :path, :disk_number

      data = service.get_vhd(
        computer_name: computer_name,
        path: path,
        disk_number: disk_number,

        _return_fields: self.class.attributes - %i[basename]
      )
      return unless data

      merge_attributes(data)
    end

    # Remove the VHD from disk
    def destroy
      requires :path

      service.remove_item(
        computer_name: computer_name,
        path: [path, "#{path}.*"],
      )
      components = path.split('\\')
      if components[-2] == vm.name
        # if (!Test-Path -Path ...\*) { Remove-Item -Path ... -Recurse -Force }
        vmpath = components[0..-2].join '\\'
        service.run_cmdlist(
          [
            ["$anyFiles = Test-Path", { path: [vmpath, '*'].join('\\') }],
            ['if (-not $anyFiles) { Remove-Item @Args }', { path: vmpath, recurse: true, force: true }]
          ],
          skip_json: true,
          target_computer: computer_name,
        )
      end
      true
    end

    # Optimizes the VHD on disk
    #
    # @param mode [:full,:pretrimmed,:prezeroed,:quick,:retrim,nil] the optimization mode to use,
    #   will default to :full/:quick depending on VHD type
    def optimize(mode: nil)
      requires :path

      service.optimize_vhd(
        computer_name: computer_name,
        path: path,
        mode: mode
      )
      true
    end

    private

    def merge_attributes(new_attributes = {})
      new_attributes[:parent_path] = nil if new_attributes[:parent_path] == ''
      new_attributes[:basename] = File.basename(new_attributes[:path].split('\\').last, '.*') if new_attributes[:path]

      super
    end

    def vhd_ext
      ext = vhd_format&.downcase || 'vhdx'
      ext = 'vhds' if ext.downcase == 'vhdset'
      ext = 'vhdx' if ext.downcase == 'unknown'
      ext
    end
  end
end
