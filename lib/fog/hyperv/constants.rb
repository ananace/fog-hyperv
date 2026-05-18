# frozen_string_literal: true

module Fog::Hyperv
  # General GUID format matching the UUIDv4 specification
  GUID = /[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}/i

  # General enum for on/off toggles as used by Hyper-V
  #
  # @note Defined by Microsoft.HyperV.PowerShell.OnOffState
  ON_OFF_STATE_ENUM_VALUES = %i[
    On
    Off
  ].freeze

  # Possible boot devices
  #
  # A few values - +:VHD+ and +:IDE+, +:NetworkAdapter+ and +:LegacyNetworkAdapter+ - refer to the same actual value,
  # but will be used depending on the generation of the VM.
  #
  # @note Defined by Microsoft.HyperV.PowerShell.BootDevice
  BOOT_DEVICE_ENUM_VALUES = %i[
    Floppy CD IDE LegacyNetworkAdapter NetworkAdapter VHD
  ].freeze
end
