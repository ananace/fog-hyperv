module Fog
  module Compute
    class Hyperv
      class Volumes < Fog::Collection
        autoload :Volume, File.expand_path('../volume', __FILE__)

        attr_accessor :computer_name
        attr_accessor :vm_name
        attr_accessor :type

        model Fog::Compute::Hyperv::Volume

        def all(filters = {})
          load get_method({
            computer_name: computer_name,
            vm_name: vm_name,
            type: type
          }.merge filters)
        end

        def get(filters = {})
          # TODO: Validation?
          #
          # uint ControllerNumber
          # uint ControllerLocation
          # enum [:IDE, :SCSI, :FLOPPY] ControllerType
          new get_method({
            vm_name: id,
            computer_name: computer_name,
            type: type
          }.merge filters)
        end

        def new(options = {})
          super({
            computer_name: computer_name,
            vm_name: vm_name,
            type: type
          }.merge(options))
        end

        private

        def get_method(args)
          case type
          when :DVD
            service.get_vm_dvd_drive(args)
          when :FDD
            service.get_vm_floppy_disk_drive(args)
          when :HDD
            service.get_vm_hard_disk_drive(args)
          end
        end
      end
    end
  end
end
