# frozen_string_literal: true

require 'fog/compute/models/server'

class Fog::Hyperv::Compute
  # rubocop:disable Metrics/ClassLength

  # A Hyper-V VM
  class Server < Fog::Compute::Server
    extend Fog::Hyperv::ModelExtends
    include Fog::Hyperv::ModelIncludes

    # rubocop:disable Layout/HashAlignment

    # VM running state
    # @note Defined by Microsoft.HyperV.PowerShell.VMState
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

    # VM object status
    # @note Defined by Microsoft.HyperV.PowerShell.VMOperationalStatus
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

    # VM generation - BIOS/UEFI
    VM_GENERATION_VALUES = {
      BIOS: 1,
      UEFI: 2
    }.freeze
    # rubocop:enable Layout/HashAlignment

    # @!attribute [r] id
    #   @return [String] the GUID of the VM
    identity :id
    alias vm_id :id

    # @!attribute [r] computer_name
    #   @return [String] the name of the host running the VM
    attribute :computer_name

    # @!attribute name
    #   @return [String] the name of the VM
    attribute :name
    alias vm_name :name
    # @!attribute [r] creation_time
    #   @return [Time] the time the VM was created
    attribute :creation_time, type: :hypervdatetime
    # @!attribute dynamic_memory_enabled
    #   @return [Boolean] is memory dynamically allocated
    attribute :dynamic_memory_enabled, type: :boolean, default: false
    # @!attribute [r] generation
    #   @return [Symbol] the generation of the VM
    attribute :generation, type: :hypervenum, values: VM_GENERATION_VALUES, default: :UEFI
    # @!attribute [r] is_clustered
    #   @return [Boolean] is the VM clustered
    attribute :is_clustered, type: :boolean, default: false
    # @!attribute [r] state
    #   @return [Symbol] the state of the VM
    #   @see VM_STATE_ENUM_VALUES
    attribute :state, type: :hypervenum, values: VM_STATE_ENUM_VALUES
    # @!attribute [r] primary_operational_status
    #   @return [Symbol] the primary status of the VM
    #   @see VM_STATUS_ENUM_VALUES
    attribute :primary_operational_status, type: :hypervenum, values: VM_STATUS_ENUM_VALUES
    # @!attribute [r] secondary_operational_status
    #   @return [Symbol] the secondary status of the VM
    #   @see VM_STATUS_ENUM_VALUES
    attribute :secondary_operational_status, type: :hypervenum, values: VM_STATUS_ENUM_VALUES
    # @!attribute [r] memory_assigned
    #   @return [Integer] the assigned memory of the VM
    attribute :memory_assigned, type: :integer
    # @!attribute memory_maximum
    #   @return [Integer] the maximum amount of memory the VM can assign
    attribute :memory_maximum, type: :integer, default: 17_179_869_184
    # @!attribute memory_minimum
    #   @return [Integer] the minimum amount of memory the VM can assign
    attribute :memory_minimum, type: :integer, default: 536_870_912
    # @!attribute memory_startup
    #   @return [Integer] the starting amount of memory the VM will assign
    attribute :memory_startup, type: :integer, default: 536_870_912
    # @!attribute notes
    #   @return [String] user-specified notes on the VM
    attribute :notes, type: :string
    # @!attribute processor_count
    #   @return [Integer] the number of processors in the VM
    attribute :processor_count, type: :integer, default: 1
    # @!attribute [r] uptime
    #   @return [Time] the time the VM was created
    attribute :uptime, type: :hypervtimespan

    collection :com_ports
    collection :dvd_drives
    collection :floppy_drives
    collection :hard_drives
    collection :network_adapters
    collection :vhds

    has_one :bios, :bios
    has_one :security, :security

    def initialize(attrs = {})
      @cluster = attrs.delete :cluster
      @computer = attrs.delete :computer

      super
    end

    # @!attribute [r] bios
    # @return [Bios,Firmware] BIOS/UEFI configuration depending on generation
    def bios
      associations[:bios] ||= begin
        requires :generation, :id
        if generation == :BIOS
          klass = Fog::Hyperv::Compute::Bios
          method = :get_vm_bios
        else
          klass = Fog::Hyperv::Compute::Firmware
          method = :get_vm_firmware
        end

        klass.new(
          **service.public_send(
            method,
            computer_name:,
            vm_id:,

            _return_fields: klass.attributes
          ),

          vm: self,
          service: @service,
          computer: @computer,
          cluster: @cluster
        )
      end
    end
    alias firmware :bios

    # @!attribute [r] security
    # @return [Security] UEFI security configuration, if #generation is 2
    def security
      requires :generation, :id
      return nil unless generation == :UEFI

      associations[:security] ||= Fog::Hyperv::Compute::Security.new(
        **service.get_vm_security(
          computer_name:,
          vm_id:,

          _return_fields: Fog::Hyperv::Compute::Security.attributes
        ),

        vm: self,
        service: @service,
        computer: @computer,
        cluster: @cluster
      )
    end

    # @!attribute [r] tpm_enabled
    # @return [Boolean] Is a vTPM enabled on the VM, only available if #generation is 2
    def tpm_enabled
      security&.tpm_enabled
    end

    def tpm_enabled=(enabled)
      return unless security
      return if enabled == tpm_enabled

      security.tpm_enabled = enabled
      security.save
      enabled # rubocop:disable Lint/Void -- Needs to shadow the result of security.save
    end

    # Start the VM
    def start
      requires :id

      service.start_vm(
        computer_name:,
        id:
      )
      true
    end

    # Stop the VM
    # @param [Boolean] turn_off send power off instead of ACPI shutdown
    # @param [Boolean] force kill the VM if it doesn't shut down cleanly
    def stop(turn_off: false, force: false)
      requires :id
      service.stop_vm(
        computer_name:,
        id:,

        turn_off:,
        force:
      )
      true
    end

    # Suspend VM execution
    def suspend
      requires :id
      service.suspend_vm(
        computer_name:,
        id:
      )
      true
    end

    # Resume suspended VM execution
    def resume
      requires :id
      service.resume_vm(
        computer_name:,
        id:
      )
      true
    end

    # Hibernate VM, i.e. suspend and save VM state to disk
    def hibernate
      requires :id
      service.save_vm(
        computer_name:,
        id:
      )
      true
    end

    # Restart the VM
    # @param [Boolean] force restart the VM if it doesn't shut down cleanly
    def restart(force: false)
      requires :id
      service.restart_vm(
        computer_name:,
        id:,

        force:
      )
      true
    end
    alias reboot :restart

    # Update the VM object to the latetest version
    def update_version
      requires :id
      service.update_vm(
        computer_name:,
        id:
      )
      true
    end

    def destroy
      requires :id
      stop turn_off: true if ready?

      service.remove_vm(
        computer_name:,
        id:
      )
      true
    end

    def create(boot_device: nil, switch_name: nil, **attrs)
      attrs[:no_vhd] = true unless attrs[:new_vhd_path]

      merge_attributes(
        service.new_vm(
          computer_name:,
          name:,

          generation: generation_num,
          memory_startup_bytes: memory_startup,
          boot_device:,
          switch_name:,

          **attrs,

          _return_fields: self.class.attributes
        )
      )

      # vhds.each do |vhd|
      #   next if hard_drives.find { |hdd| hdd.path == vhd.path }
      #
      #   hard_drives.new(path: vhd.path)
      # end
      #
      # self.class.associations.each_key do |assoc|
      #   next unless attributes.key? assoc
      #
      #   attributes[assoc].each(&:save)
      # end

      self
    end

    def update
      requires :id

      if changed?(:name)
        service.rename_vm(
          computer_name: old.computer_name,
          id: old.id,

          new_name: name
        )
        @old.name = name
      end

      data = service.set_vm(
        computer_name: old.computer_name,
        id: old.id,

        processor_count: changed!(:processor_count),
        dynamic_memory: changed?(:dynamic_memory_enabled) && dynamic_memory_enabled,
        static_memory: changed?(:dynamic_memory_enabled) && !dynamic_memory_enabled,
        memory_minimum_bytes: changed?(:memory_minimum) && dynamic_memory_enabled && memory_minimum,
        memory_maximum_bytes: changed?(:memory_maximum) && dynamic_memory_enabled && memory_maximum,
        memory_startup_bytes: changed!(:memory_startup),
        notes: changed!(:notes),
        new_name: changed!(:name),

        _return_fields: self.class.attributes
      )

      merge_attributes(data)

      # %i[network_adapters dvd_drives floppy_drives hard_drives vhds].each do |attr|
      #   next unless attributes.key? attr
      #
      #   attributes[attr].each { |vhd| hard_drives.new(path: vhd.path).save } if attr == :vhds
      #   attributes[attr].select(&:dirty?).each(&:save)
      # end
    end

    # Reload the VM attributes from the Hyper-V server
    # @return [self] if model successfully reloaded
    # @return [nil] if something went wrong or model was not found
    def reload
      requires :id

      data = service.get_vm(
        computer_name:,
        id:,

        _return_fields: self.class.attributes
      )
      return unless data

      merge_attributes(data)
      @old = data

      self
    end

    # Build a path for where to store a VHD of a given name
    # @return [String] the absolute path for the VHD
    def build_vhd_path(filename)
      requires :name

      [computer.virtual_hard_disk_path, '\\', name, '\\', filename].join
    end

    def username
      @username || 'Administrator'
    end

    # @return [Boolean] is the VM ready? (i.e. state is +:Running+)
    def ready?
      state_num == 2
    end

    # @return [Array<String>] the MAC addresses of all attached network adapters
    def mac_addresses
      network_adapters.map(&:mac_address)
    end

    # @return [Array<String>] the IP addresses of all attached network adapters
    def ip_addresses
      network_adapters.map(&:ip_addresses).flatten
    end

    # @return [Array<String>] the public (not link-local) IP addresses of all attached network adapters
    def public_ip_addresses
      ip_addresses
        .map { |a| IPAddr.new a }
        .reject(&:link_local?)
        .map(&:to_s)
    end

    def public_ip_address
      public_ip_addresses.first
    end
  end
  # rubocop:enable Metrics/ClassLength
end
