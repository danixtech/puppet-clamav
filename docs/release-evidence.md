# Modernization release evidence

This matrix is the release-readiness record for the modernization branch. A
catalog result is not a runtime support claim; formal claims require the
complete CI and Litmus evidence listed below.

| Runtime | Package source | Catalog evidence | Runtime evidence | Formal status |
| --- | --- | --- | --- | --- |
| Puppet 8 / Ubuntu 24.04 | Ubuntu archive/security packages | CI validation and complete unit suite | Runtime acceptance: [30664438627](https://github.com/danixtech/puppet-clamav/actions/runs/30664438627) | Formally supported |
| Puppet 8 / Debian 12 | Debian distribution packages | CI validation and complete unit suite | Runtime acceptance: [30664438627](https://github.com/danixtech/puppet-clamav/actions/runs/30664438627) | Formally supported |
| Puppet 8 / AlmaLinux 9 | EPEL/distro-style packages | CI validation and EPEL integration | Runtime acceptance: [30664438627](https://github.com/danixtech/puppet-clamav/actions/runs/30664438627) | Formally supported |
| OpenVox 8 / supported OSes | Distribution-native packages | OpenVox unit suite and metadata validation | No OpenVox agent runtime evidence | Source/catalog tested only |

The exact CI evidence for the current modernization tip is [30664438636](https://github.com/danixtech/puppet-clamav/actions/runs/30664438636). The runtime workflow covers package installation, configuration parsing, service state, database behavior, scanning, and convergence on the three formally supported operating systems.

## Explicit exclusions

The following are not release claims:

| Target or feature | Status | Rationale |
| --- | --- | --- |
| Debian 13 | Provisional | The required Puppet 8 installer/package path is not currently reproducible in acceptance. |
| EL10 | Provisional | Package names and service behavior require separate platform work and evidence. |
| Ubuntu 26.04 | Unsupported | No catalog or runtime evidence. |
| ClamAV 1.5+ outside Ubuntu 24.04 distro packaging | Unsupported as a general version claim | Enterprise Linux packages and Cisco/Talos installers do not provide the distro integration assumed by this module. |
| ClamAV 1.5+ FIPS | Unsupported claim | FIPS behavior is characterized but lacks a complete maintained runtime matrix. |
| clamonacc as a formal feature claim | Excluded from release claim | The interface and runtime work are present, but package/version coverage is not a general support guarantee. |

Distribution-native packages remain the supported integration model. Cisco/Talos
installer packages, private repositories, and site-specific service/account
integration are external policy and are not silently included in these claims.
