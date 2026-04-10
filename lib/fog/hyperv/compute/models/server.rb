# frozen_string_literal: true

require 'fog/compute/models/server'
require 'fog/hyperv/model'

module Fog
  module Hyperv
    class Compute
      class Server < Fog::Compute::Server
        extend Fog::Hyperv::ModelExtends
        include Fog::Hyperv::ModelIncludes

        # rubocop:disable Layout/HashAlignment
        # Microsoft.HyperV.PowerShell.VMState
        VM_STATE_ENUM_VALUES = {
          Other:              1,
          Running:            2,
          Off:                3,
          Stopping:           4,
          Saved:              6,
          Paused:             9,
          Starting:           10,
          Reset:              11,
          Saving:             32_773,
          Pausing:            32_776,
          Resuming:           32_777,
          FastSaved:          32_779,
          FastSaving:         32_780,
          ForceShutdown:      32_781,
          ForceReboot:        32_782,
          Hibernated:         32_783,
          ComponentServicing: 32_784,
          RunningCritical:    32_785,
          OffCritical:        32_786,
          StoppingCritical:   32_787,
          SavedCritical:      32_788,
          PausedCritical:     32_789,
          StartingCritical:   32_790,
          ResetCritical:      32_791,
          SavingCritical:     32_792,
          PausingCritical:    32_793,
          ResumingCritical:   32_794,
          FastSavedCritical:  32_795,
          FastSavingCritical: 32_796
        }.freeze

        # Microsoft.HyperV.PowerShell.VMOperationalStatus
        VM_STATUS_ENUM_VALUES = {
          Ok:                        2,
          Degraded:                  3,
          PredictiveFailure:         5,
          InService:                 11,
          Dormant:                   15,
          SupportingEntityInError:   16,
          CreatingSnapshot:          32_768,
          ApplyingSnapshot:          23_769,
          DeletingSnapshot:          32_770,
          WaitingToStart:            32_771,
          MergingDisks:              32_772,
          ExportingVirtualMachine:   32_773,
          MigratingVirtualMachine:   32_774,
          BackingUpVirtualMachine:   32_776,
          ModifyingUpVirtualMachine: 32_777,
          StorageMigrationPhaseOne:  32_778,
          StorageMigrationPhaseTwo:  32_779,
          MigratingPlannedVm:        32_780,
          CheckingCompatibility:     32_781,
          ApplicationCriticalState:  32_782,
          CommunicationTimedOut:     32_783,
          CommunicationFailed:       32_784,
          NoIommu:                   32_785,
          NoIovSupportInNic:         32_786,
          SwitchNotInIovMode:        32_787,
          IovBlockedByPolicy:        32_788,
          IovNoAvailResources:       32_789,
          IovGuestDriversNeeded:     32_790,
          CriticalIoError:           32_795
        }.freeze
        # rubocop:enable Layout/HashAlignment

        identity :id, type: :string

        attribute :name, type: :string
        attribute :computer_name, type: :string
        attribute :com_port1
        attribute :com_port2
        attribute :dynamic_memory_enabled, type: :boolean, default: false
        attribute :generation, type: :integer, default: 1 # 1 => bios, 2 => uefi
        attribute :is_clustered, type: :boolean, default: false
        attribute :state, type: :enum, values: VM_STATE_ENUM_VALUES
        attribute :status, type: :string # :enum, values: VM_STATUS_ENUM_VALUES
        attribute :memory_assigned, type: :integer
        attribute :memory_maximum, type: :integer, default: 17_179_869_184
        attribute :memory_minimum, type: :integer, default: 536_870_912
        attribute :memory_startup, type: :integer, default: 536_870_912
        attribute :notes, type: :string
        attribute :processor_count, type: :integer, default: 1

        lazy_attributes :network_adapters,
                        :dvd_drives,
                        :hard_drives,
                        :floppy_drive

        attr_accessor :cluster_name

        %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
          define_method attr do
            attributes[attr] ||= if persisted?
                                   service.send(attr, vm: self)
                                 else
                                   [].tap do |arr|
                                     arr.instance_variable_set :@klass, Fog::Hyperv::Compute.const_get(
                                       Fog::Hyperv.camelize(attr.to_s.chop).to_sym
                                     )
                                     arr.instance_variable_set :@vm, self
                                     arr.instance_variable_set :@service, service

                                     arr.instance_eval do
                                       def new(**attributes)
                                         self << @klass.new(
                                           attributes.merge(
                                             computer_name: @vm.computer_name,
                                             vm_name: @vm.name,
                                             vm: @vm,
                                             service: @service
                                           )
                                         )
                                       end
                                     end
                                   end
                                 end
          end
        end

        def initialize(attrs = {})
          super

          %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
            next unless attrs.key? attr

            attributes[attr] = attrs.delete(attr).map do |data|
              service.public_send(attr, vm: self).new(data)
            end
          end

          @cluster = attrs.delete :cluster
          @computer = attrs.delete :computer
        end

        def bios
          @bios ||= begin
            if generation == 1
              klass = Fog::Hyperv::Compute::Bios
              method = :get_vm_bios
            else
              klass = Fog::Hyperv::Compute::Firmware
              method = :get_vm_firmware
            end

            klass.new(
              service.public_send(
                method,
                computer_name: computer_name,
                vm_name: name,

                _return_fields: klass.attributes
              ).merge(service: service)
            )
          end
        end
        alias firmware :bios

        def security
          @security ||= begin
            security = Fog::Hyperv::Compute::Security.new(
              service.get_vm_security(
                computer_name: computer_name,
                vm_name: name,

                _return_fields: Fog::Hyperv::Compute::Security.attributes
              ).merge(
                service: service
              )
            )
            security.instance_variable_set :@vm, self
            security
          end
        end

        def tpm_enabled
          security.tpm_enabled
        end

        def tpm_enabled=(enabled)
          return if enabled == tpm_enabled?

          security.tpm_enabled = enabled
          security.save
        end

        alias vm_id :id
        alias vm_name :name

        def start(**options)
          requires :name, :computer_name
          service.start_vm(
            name: name,
            computer_name: computer_name,
            **options
          )
        end

        def stop(**options)
          requires :name, :computer_name
          service.stop_vm(
            name: name,
            computer_name: computer_name,
            **options
          )
        end

        def restart(**options)
          requires :name, :computer_name
          service.restart_vm(
            name: name,
            computer_name: computer_name,
            **options
          )
        end
        alias reboot :restart

        def destroy(**options)
          requires :name, :computer_name
          stop turn_off: true if ready?
          service.remove_vm(
            name: name,
            computer_name: computer_name,
            **options
          )
        end

        def add_interface(**options)
          network_adapters.create(**options)
        end

        def save(**options)
          requires :name

          if persisted?
            data = service.set_vm(
              _return_fields: self.class.attributes,
              _json_depth: 1,

              **options.merge(
                computer_name: old.computer_name,
                name: old.name,
                passthru: true,

                processor_count: changed!(:processor_count),
                dynamic_memory: changed?(:dynamic_memory_enabled) && dynamic_memory_enabled,
                static_memory: changed?(:dynamic_memory_enabled) && !dynamic_memory_enabled,
                memory_minimum_bytes: changed?(:memory_minimum) && dynamic_memory_enabled && memory_minimum,
                memory_maximum_bytes: changed?(:memory_maximum) && dynamic_memory_enabled && memory_maximum,
                memory_startup_bytes: changed!(:memory_startup),
                notes: changed!(:notes),
                new_name: changed!(:name)
              )
            )
          else
            # TODO: Apply predefined config onto created VM
            usable = %i[name memory_startup generation boot_device switch_name no_vhd new_vhd_path new_vhd_size_bytes].freeze
            data = service.new_vm \
              attributes.slice(*usable)
                        .merge(options)
                        .merge(_return_fields: self.class.attributes, _json_depth: 1)
          end

          merge_attributes(data)

          %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
            attributes[attr]&.select(&:dirty?)&.each(&:save)

            attributes[attr].each { |vhd| hard_drives.new(path: vhd.path).save } if attr == :vhds && attributes[attr]

            # Reset pre-persist lazy attributes to become true collections
            attributes[attr] = nil if attributes[attr].is_a?(Array)
          end

          @old = dup
          self
        end

        def reload
          data = collection.get id

          clear_lazy
          merge_attributes(data.attributes)
          @old = data
          self
        end

        def ready?
          state_num == 2
        end

        def mac_addresses
          network_adapters.map(&:mac_address)
        end

        def ip_addresses
          network_adapters.map(&:ip_addresses).flatten
        end

        def public_ip_addresses
          ip_addresses
            .map { |a| IPAddr.new a }
            .reject(&:link_local?)
            .map(&:to_s)
        end

        def merge_attributes(new_attributes = {})
          %i[com_port1 com_port2].each do |attr|
            comport = new_attributes[attr]
            if comport.is_a? Hash
              new_attributes[attr] = Fog::Hyperv::Compute::ComPort.new(comport)
            elsif comport.is_a? String
              attrs = comport.scan(%r{(\w+) = '([^']+)'}).to_h { |k, v| [Fog::Hyperv.uncamelize(k), v]}
              new_attributes[attr] = Fog::Hyperv::Compute::ComPort.new(attrs)
            end
          end

          super
        end
      end
    end
  end
end
