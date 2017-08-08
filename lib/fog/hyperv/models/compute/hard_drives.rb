module Fog
  module Compute
    class Hyperv
      class HardDrives < Fog::Collection
        autoload :HardDrive, File.expand_path('../hard_drive', __FILE__)

        attr_accessor :computer_name
        attr_accessor :vm_name

        model Fog::Compute::Hyperv::HardDrive

        def all(filters = {})
          load [service.get_vm_hard_disk_drive({
            computer_name: computer_name,
            vm_name: vm_name,
            _return_fields: model.attributes,
            _json_depth: 1
          }.merge(filters))].flatten
        end

        def get(filters = {})
          new service.get_vm_hard_disk_drive({
            computer_name: computer_name,
            vm_name: vm_name,
            _return_fields: model.attributes,
            _json_depth: 1
          }.merge(filters))
        end

        def new(options = {})
          super({
            computer_name: computer_name,
            vm_name: vm_name
          }.merge(options))
        end
      end
    end
  end
end
