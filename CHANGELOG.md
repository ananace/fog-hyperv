## v0.0.6 **Unreleased**

- Ensure that computer and cluster names are always present in collections
- Allow caching direct assignment of computer/cluster
- More enum fixes to standardise key and value types
- Add a check for cluster support
- Make sure to not pass along internal variables to the PSRemoting shell

## v0.0.5 2017-11-14

- Remove lefover debugging outputs

## v0.0.4 2017-11-14

- Adds support for the Kerberos transport
- Implements a first prototype for multi-hop when not using Kerberos/CredSSP
- Fixes issues in the saving of a few models
- Fixes a major issue when a VM ends up in a state with a large numerical value
  - An issue in the enum code made input validity checking unable to differentiate between hashes and arrays

## v0.0.3 2017-08-30

- Fixes handling of BIOS/Firmware
- Skips unnecessary Hyper-V calls when checking dirty status
- Adds some possible interface improvements when dealing with clusters

## v0.0.2 2017-08-28

- Reduces `fog-core` dependency to 1.42
- Disables `status` attribute for network adapters, due to Hyper-V 6.3 issues

## v0.0.1 2017-08-25

- Initial release
