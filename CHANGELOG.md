## v0.0.4 *unreleased*

- Adds support for the Kerberos transport
- Implements a first prototype for multi-hop when not using Kerberos/CredSSP
- Fixes issues in the saving of a few models
- Fixes a major issue when a VM ends up in a state with a large numerical value
  - Due to an issue in the enum lookup where input validity checking assumed hashes where arrays

## v0.0.3 2017-08-30

- Fixes handling of BIOS/Firmware
- Skips unnecessary Hyper-V calls when checking dirty status
- Adds some possible interface improvements when dealing with clusters

## v0.0.2 2017-08-28

- Reduces `fog-core` dependency to 1.42
- Disables `status` attribute for network adapters, due to Hyper-V 6.3 issues

## v0.0.1 2017-08-25

- Initial release
