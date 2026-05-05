# frozen_string_literal: true

class Fog::Hyperv::Compute
  class Host < Fog::Hyperv::Model
    # @!attribute [r] name
    #   @return [String] the name of the host
    identity :name
    alias computer_name :name

    # @!attribute [r] fully_qualified_domain_name
    #   @return [String] the FQDN of this host
    attribute :fully_qualified_domain_name
    # @!attribute [r] logical_processor_count
    #   @return [Integer] the number of logical CPUs on this host
    attribute :logical_processor_count, type: :integer
    # @!attribute [r] memory_capacity
    #   @return [Integer] the amount of memory on this host
    attribute :memory_capacity, type: :integer
    # @!attribute [r] mac_address_minimum
    #   @return [String] the lowest possible MAC address for VMs on this host
    attribute :mac_address_minimum
    # @!attribute [r] mac_address_maximum
    #   @return [String] the highest possible MAC address for VMs on this host
    attribute :mac_address_maximum
    # @!attribute [r] maximum_storage_migrations
    #   @return [String] the maximum number of simulatenous storage migrations on this host
    attribute :maximum_storage_migrations, type: :integer
    # @!attribute [r] maximum_virtual_machine_migrations
    #   @return [String] the maximum number of simulatenous VMM migrations on this host
    attribute :maximum_virtual_machine_migrations, type: :integer
    # @!attribute [r] virtual_hard_disk_path
    #   @return [String] the path where VHDs will be stored on this host
    attribute :virtual_hard_disk_path
    # @!attribute [r] virtual_machine_path
    #   @return [String] the path where VMs will be stored on this host
    attribute :virtual_machine_path

    collection :network_adapters
    collection :servers
    collection :switches

    # @!attribute [r] secure_boot_templates
    # @return [Array<String>] the available secure boot templates on this host
    def secure_boot_templates
      @secure_boot_templates ||= service.get_vm_host_sbt(computer_name: name)
    end

    def reload
      requires :name

      data = service.get_vm_host(
        computer_name:,
        name:
      )
      return unless data

      merge_attributes(data)
    end
  end
end
