# frozen_string_literal: true

require 'fog/compute/models/server'

class Fog::Hyperv::Compute
  # rubocop:disable Metrics/ClassLength

  # A Hyper-V VM
  class Server < Fog::Compute::Server
    extend Fog::Hyperv::ModelExtends
    include Fog::Hyperv::ModelIncludes

    # rubocop:disable Layout/HashAlignment

    # VM runtime state
    #
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
    #
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

    # VM firmware generation - i.e. BIOS/UEFI
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
    #   @return [Boolean] if memory is dynamically handled - sliding between #memory_minimum and #memory_maximum
    attribute :dynamic_memory_enabled, type: :boolean, default: false
    # @!attribute [r] generation
    #   @return [Symbol] the VM firmware generation
    attribute :generation, type: :hypervenum, values: VM_GENERATION_VALUES, default: :UEFI
    # @!attribute [r] is_clustered
    #   @return [Boolean] iv the VM is clustered
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
    #   @return [Integer] the memory assigned to the VM on startup
    attribute :memory_assigned, type: :integer
    # @!attribute memory_maximum
    #   @return [Integer] the maximum amount of memory the VM can assign when #dynamic_memory_enabled
    attribute :memory_maximum, type: :integer, default: 17_179_869_184
    # @!attribute memory_minimum
    #   @return [Integer] the minimum amount of memory the VM can assign when #dynamic_memory_enabled
    attribute :memory_minimum, type: :integer, default: 536_870_912
    # @!attribute memory_startup
    #   @return [Integer] the starting amount of memory the VM will be assigned
    attribute :memory_startup, type: :integer, default: 536_870_912
    # @!attribute notes
    #   @return [String] user-specified notes for the VM
    attribute :notes, type: :string
    # @!attribute processor_count
    #   @return [Integer] the number of processors in the VM
    attribute :processor_count, type: :integer, default: 1
    # @!attribute [r] uptime
    #   @return [Time] the amount of time the VM has been online
    attribute :uptime, type: :hypervtimespan

    # @!attribute com_ports
    #   @return [Array<ComPort>] the COM ports on the VM
    collection :com_ports
    # @!attribute dvd_drives
    #   @return [Array<DvdDrive>] the DVD drives on the VM
    collection :dvd_drives
    # @!attribute floppy_drives
    #   @note only supported on #generation +:BIOS+
    #   @return [Array<FloppyDrive>] the floppy drives on the VM
    collection :floppy_drives
    # @!attribute hard_drives
    #   @return [Array<HardDrive>] the hard drives on the VM
    collection :hard_drives
    # @!attribute integration_services
    #   @return [Array<IntegrationService>] the integration services on the VM
    collection :integration_services
    # @!attribute network_adapters
    #   @return [Array<NetworkAdapter>] the network adapters on the VM
    collection :network_adapters
    # @!attribute vhds
    #   @return [Array<Vhd>] the VHD images in use by the VM
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
            computer_name: computer_name,
            vm_id: vm_id,

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
    # @return [Security] UEFI security configuration, if #generation is +:UEFI+
    def security
      return unless persisted?

      requires :generation
      return unless generation == :UEFI

      security = service.get_vm_security(
        computer_name: computer_name,
        vm_id: vm_id,

        _return_fields: Fog::Hyperv::Compute::Security.attributes
      )
      return unless security.is_a? Hash

      associations[:security] ||= Fog::Hyperv::Compute::Security.new(
        **security,

        vm: self,
        service: @service,
        computer: @computer,
        cluster: @cluster
      )
    end

    # @!attribute tpm_enabled
    # @return [Boolean] if a vTPM is enabled on the VM, only available if #generation is +:UEFI+
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

      service.start_vm(computer_name: computer_name, id: id)
      true
    end

    # Stop the VM
    # @param [Boolean] turn_off perform an instant power off instead of an ACPI shutdown
    def stop(turn_off: false)
      requires :id

      service.stop_vm(computer_name: computer_name, id: id, turn_off: turn_off)
      true
    end

    # Suspend VM execution
    def suspend
      requires :id

      service.suspend_vm(computer_name: computer_name, id: id)
      true
    end

    # Resume suspended VM execution
    def resume
      requires :id

      service.resume_vm(computer_name: computer_name, id: id)
      true
    end

    # Hibernate the VM, i.e. save VM state to disk and turn it off
    def hibernate
      requires :id

      service.save_vm(computer_name: computer_name, id: id)
      true
    end

    # Restart the VM
    # @note This method will always cause a hard reset, i.e. power off and on without waiting for OS shutdown
    def restart
      requires :id

      service.restart_vm(computer_name: computer_name, id: id)
      true
    end
    alias reboot :restart

    # Update the VM object to the latest version
    def update_version
      requires :id

      service.update_vm(computer_name: computer_name, id: id)
      true
    end

    # Remove the VM object from Hyper-V
    #
    # @note if the VM has VHDs, make sure to remove them first to not leave the VM data remaining on disk
    def destroy
      requires :id
      stop turn_off: true if ready?

      service.remove_vm(computer_name: computer_name, id: id)
      true
    end

    # Create the VM object if it doesn't exist
    # @param [Symbol] boot_device the default boot device to configure the VM with, one of BOOT_DEVICE
    # @param [String] switch_name the name of a Switch to connect the VM to on creation
    def create(boot_device: nil, switch_name: nil, **attrs)
      attrs[:no_vhd] = true unless attrs[:new_vhd_path]

      # Attributes that can't be set as part of the New-VM call
      post_create_attributes = {
        processor_count: processor_count > 1 ? processor_count : nil,
        notes: notes.nil? || notes == '' ? nil : notes
      }
      if dynamic_memory_enabled
        post_create_attributes.merge!(
          dynamic_memory_enabled: true,
          memory_minimum_bytes: memory_minimum,
          memory_maximum_bytes: memory_maximum
        )
      end
      post_create_attributes.compact!

      merge_attributes(
        service.new_vm(
          computer_name: computer_name,
          name: name,

          generation: generation_num,
          memory_startup_bytes: memory_startup,
          boot_device: boot_device,
          switch_name: switch_name,

          **attrs,

          _return_fields: self.class.attributes
        )
      )
      attributes.merge! post_create_attributes if post_create_attributes.any?
      save if dirty?

      # Save any associations that have been manually assigned before VM creation
      self.class.associations.each_key do |assoc|
        next unless associations.key? assoc

        associations[assoc].select do |obj|
          obj.computer_name = computer_name if obj.respond_to?(:computer_name=)
          obj.vm_id = id if obj.respond_to?(:vm_id=)

          obj.save if obj.dirty? || !obj.persisted?
          next if assoc != :vhd || hard_drives.none? { |hdd| hdd.path == vhd.path }

          hard_drives.create(path: vhd.path)
        end
        associations[assoc].clear
      end

      self
    end

    def update
      requires :id

      changes = {
        processor_count: changed!(:processor_count),
        memory_startup_bytes: changed!(:memory_startup),
        new_vm_name: changed!(:name)
      }.compact
      if dynamic_memory_enabled
        changes[:dynamic_memory] = true if changed?(:dynamic_memory_enabled)
        changes[:memory_minimum_bytes] = memory_minimum if changed?(:dynamic_memory_enabled, :memory_minimum)
        changes[:memory_maximum_bytes] = memory_maximum if changed?(:dynamic_memory_enabled, :memory_maximum)
      elsif changed?(:dynamic_memory_enabled)
        changes[:static_memory] = true
      end
      changes.compact!

      changes[:notes] = notes || '' if changed? :notes
      return self unless changes.any?

      merge_attributes(
        service.set_vm(
          computer_name: old.computer_name,
          id: old.id,

          **changes,

          _always_include: changes.keys,
          _return_fields: self.class.attributes
        )
      )
    end

    # Reload the VM attributes from the Hyper-V server
    # @return [self] if model successfully reloaded
    # @return [nil] if something went wrong or the model was not found
    def reload
      requires :id

      data = service.get_vm computer_name: computer_name, id: id, _return_fields: self.class.attributes
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

    # Get the username of the main system account
    # @return [String] the system account username - usually "Administrator" or "root"
    def username
      @username || 'Administrator'
    end

    # @return [Boolean] if the VM is ready? (i.e. #state is +:Running+)
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

    # @return [String,nil] the first public IP address of the VM - if any
    def public_ip_address
      public_ip_addresses.first
    end
  end
  # rubocop:enable Metrics/ClassLength
end
