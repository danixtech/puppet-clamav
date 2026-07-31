# Package policy

This document records the package contract for the standalone module. It is a
design boundary for issue #21; it does not change the existing defaults.

## Current compatibility

All component version parameters retain their established default of `latest`.
Callers may continue to set the public component-specific version parameters
(`clamav_version`, `clamd_version`, `freshclam_version`, and
`clamav_milter_version`) independently. The module does not silently change
those defaults to `installed`.

The supported integration model is distribution-native packaging:

* repository selection and trust are managed externally or through the existing
  distro integration;
* Puppet manages normal package resources and the package-provided paths,
  accounts, dependencies, and service units;
* component packages may be absent when the corresponding component is not
  managed.

The tested Enterprise Linux path is EPEL's split ClamAV packaging. The
official Cisco/Talos installer RPM and DEB artifacts are not treated as
interchangeable with those packages.

## Explicitly unsupported package behavior

The module does not clone or build ClamAV source during a Puppet run, download
private repositories, act as an artifact-distribution service, or silently
recreate vendor package integration with local accounts, units, and directory
policy. Detached-signature verification and artifact promotion remain external
responsibilities.

## Future policy design

A later implementation may introduce a typed global package policy with
component overrides, but any change from `latest` requires an explicit release
decision and migration guidance. An optional externally integrated vendor
package mode would require a complete caller-supplied contract for package
name/version, prefix and binary paths, configuration paths, service units,
accounts, runtime/database directories, and dependencies, plus catalog and
runtime evidence. It must not become a vendor-specific autodetection path.
