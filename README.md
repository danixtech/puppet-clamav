clamav
=============

[![CI](https://github.com/danixtech/puppet-clamav/actions/workflows/ci.yml/badge.svg)](https://github.com/danixtech/puppet-clamav/actions/workflows/ci.yml)
[![Runtime acceptance](https://github.com/danixtech/puppet-clamav/actions/workflows/acceptance.yml/badge.svg)](https://github.com/danixtech/puppet-clamav/actions/workflows/acceptance.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/edestecd/clamav.svg)](https://forge.puppet.com/edestecd/clamav)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/edestecd/clamav.svg)](https://forge.puppet.com/edestecd/clamav)
[![Puppet Forge Score](https://img.shields.io/puppetforge/f/edestecd/clamav.svg)](https://forge.puppet.com/edestecd/clamav/scores)

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with clamav](#setup)
    * [What clamav affects](#what-clamav-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with clamav](#beginning-with-clamav)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors](#contributors)

## Overview

Puppet Module to install/configure clamd and freshclam on Debian and RedHat

## Module Description

The clamav module provides classes to install and configure the main ClamAV
components. You may manage only the components you need. The module supplies
baseline configuration defaults and combines them with platform data and
caller overrides.

This module has the following components that can be managed (or not):
* Base clamav package - command line and libs
* clamav user
* clam daemon
* freshclam daemon/cron (dependent on OS)
* clamav-milter (RHEL7 and derivatives only for now)

## Setup

### What clamav affects

* clamav/clamd/freshclam package install
* clamav/clamd/freshclam config files
* clamd/freshclam services or daily cron on redhat
* clamav-milter package install, config files, service (optional)
* clam user/group (optional)

### Setup Requirements

Install the module and its dependencies. On Red Hat-family systems,
`manage_repo` defaults to `true` and declares the module's `puppet/epel`
dependency. Set `manage_repo => false` when repository management is provided
elsewhere.

The supported default integration model uses distribution-native package
layouts, including Ubuntu and Debian archive packages and Enterprise Linux
packages supplied through EPEL or an equivalent distribution-style
repository. Official Cisco/Talos installer DEB/RPM packages are not assumed to
provide the same paths, accounts, package splits, systemd units, or runtime
directories. The module does not download or build ClamAV source. Any future
installer-package support requires an explicit external package-integration
contract; repository locations and organization-specific packaging remain
caller policy.

### Beginning with clamav

Minimal clamav package install for command line use:

```puppet
include clamav
```

## Usage

### Manage the clam and freshclam daemon with stock config

```puppet
class { 'clamav':
  manage_clamd             => true,
  manage_freshclam         => true,
  clamd_service_ensure     => 'running',
  freshclam_service_ensure => 'stopped',
}
```

### Also manage the clam user and group

```puppet
class { 'clamav':
  manage_user      => true,
  uid              => 499,
  gid              => 499,
  shell            => '/sbin/nologin',
  manage_clamd     => true,
  manage_freshclam => true,
}
```

### Customize the clamd and freshclam config

```puppet
class { 'clamav':
  manage_clamd      => true,
  manage_freshclam  => true,
  clamd_options     => {
    'MaxScanSize' => '500M',
    'MaxFileSize' => '150M',
  },
  freshclam_options => {
    'LogTime'         => 'yes',
    'HTTPProxyServer' => 'myproxy.proxy.com',
    'HTTPProxyPort'   => '80',
    'NotifyClamd'     => '/etc/clamd.conf',
    'DatabaseMirror'  => [
      'clam.host1.mydomain.com',
      'clam.host2.mydomain.com',
    ],
  },
}
```

### Understand clamd option precedence

When `clamd_default_options` is not supplied, the generated configuration uses
these layers, with later values taking precedence:

1. Module baseline options.
2. OS-family platform options.
3. Caller-supplied `clamd_options`.

For compatibility with earlier releases, explicitly supplying
`clamd_default_options` replaces both the module baseline and platform
defaults. `clamd_options` is then applied over that replacement hash. A
replacement hash must therefore contain every default required by the target
system.

An option whose value is `undef` or an empty string is omitted. Arrays render
the directive once for each non-empty element. Boolean values retain the
module's established `true` and `false` rendering.

### Enable clamd socket activation explicitly

Direct service management remains the default. Debian-family systems provide
`clamav-daemon.socket` as the default socket unit, but it is used only when
socket activation is explicitly enabled:

```puppet
class { 'clamav':
  manage_clamd     => true,
  clamd_use_socket => true,
}
```

The module keeps the direct clamd service stopped and disabled while the
socket unit is active. A custom socket unit can be supplied with
`clamd_socket`. Enabling socket activation on a platform without a socket-unit
default requires an explicit `clamd_socket` value.

The compatibility configuration renders `LocalSocketMode 666`, allowing any
local account that can reach the socket path to connect. Sites that do not
require world-accessible scanning should restrict the socket to its configured
group:

```puppet
class { 'clamav':
  manage_clamd  => true,
  clamd_options => {
    'LocalSocketMode' => '660',
  },
}
```

Ensure every local client that needs the socket belongs to the configured
`LocalSocketGroup` before applying a restrictive mode. The module retains
`666` as its compatibility default; changing that default requires a
separately documented migration.

### Understand freshclam service policy

Debian-family systems manage the `clamav-freshclam` service directly.
Red Hat-family EL7 packages use their cron-based update behavior, so the
module does not declare a freshclam service there. EL8 manages the
`clamav-freshclam` service and its `/etc/sysconfig/freshclam` environment
file.

### Define the clamonacc interface

On-access scanning remains disabled by default:

```puppet
class { 'clamav':
  manage_clamonacc => false,
}
```

The Stage 2 interface foundation accepts package-neutral operational inputs
without yet managing a clamonacc package, configuration file, service,
directory, or quarantine action. Operational support is being added
separately so that package paths and service integration can be validated
before the module claims clamonacc support.

The public contract includes:

* optional package name/version, binary path, configuration path, and service
  name;
* typed service `ensure` (`running` or `stopped`) and enable policy;
* `LocalSocket` or `TCPSocket` listen mode;
* daemon username;
* one or more absolute include paths;
* optional absolute exclude paths, excluded usernames, temporary directory,
  and quarantine path;
* `clamonacc_options` for compatible native/component options.

At least one include path is required when `manage_clamonacc` is true. Named
typed parameters take precedence over equivalent compatibility keys in
`clamonacc_options`. The preserved compatibility keys are `ListenMode`,
`DaemonUsername`, `OnAccessIncludePath`, `OnAccessExcludePath`,
`OnAccessExcludeUname`, and `TemporaryDirectory`.

For example, this declares and validates the interface only:

```puppet
class { 'clamav':
  manage_clamonacc             => true,
  clamonacc_include_paths      => ['/srv/data'],
  clamonacc_exclude_paths      => ['/srv/data/quarantine'],
  clamonacc_exclude_usernames  => ['clamav'],
  clamonacc_temporary_directory => '/var/tmp/clamonacc',
  clamonacc_quarantine_path    => '/srv/data/quarantine',
}
```

These paths are examples rather than module defaults. Package and binary
locations are intentionally optional so later platform data can describe
distribution-native layouts without assuming that Cisco/Talos installers
provide equivalent integration. Do not treat this interface-only stage as
operational clamonacc support. `clamav::clamonacc` can also be declared
directly with the same child-class parameters. Resource ordering remains an
internal module responsibility once later stages add resources; this
foundation does not expose resource-reference relationship parameters.

### Validate configuration before service refresh

Managed clamd, freshclam, and milter files are validated with their
package-provided binaries before Puppet replaces the live configuration.
Validation failure leaves the existing file in place, so its service
subscription is not refreshed with rejected content.

The default commands use `/usr/bin/env` to resolve distribution package paths:

```text
/usr/bin/env clamd --config-file % --version
/usr/bin/env freshclam --config-file % --version
/usr/bin/env clamav-milter --config-file % --version
```

Callers using custom packages can replace the commands with
`clamd_config_validate_cmd`, `freshclam_config_validate_cmd`, and
`milter_config_validate_cmd`. Set `validate_configs => false` only for a
platform whose package has no safe parse-only interface. Disabling validation
permits invalid caller options to reach the live file and is not recommended.

### Add clamav-milter support and customize its config (RHEL7 and derivatives only)
#### Please note that as of RHEL 7.2 only the TCP socket has been tested successfully

```puppet
class { 'clamav':
  manage_repo           => false,
  clamd_options         => {
    'TCPSocket' => '3310',
    'TCPAddr'   => '127.0.0.1',
  },

  clamav_milter_options => {
    'AddHeader'  => 'add',
    'OnInfected' => 'Reject',
    'RejectMsg'  => 'Message rejected: Infected by %v',
  },

  manage_clamd          => true,
  manage_freshclam      => true,
  manage_clamav_milter  => true,
  clamd_service_ensure  => 'running',
}
```

### Configure with hiera yaml

```puppet
include clamav
```
```yaml
---
clamav::manage_clamd: true
clamav::manage_freshclam: true

clamav::clamd_options:
  MaxScanSize: 500M
  MaxFileSize: 150M
clamav::freshclam_options:
  LogTime: yes
  HTTPProxyServer: myproxy.proxy.com
  HTTPProxyPort: 80
  NotifyClamd: /etc/clamd.conf
  DatabaseMirror:
  - clam.host1.mydomain.com
  - clam.host2.mydomain.com
```

## Reference

### Classes

* clamav
* clamav::user
* clamav::clamd
* clamav::freshclam
* clamav::clamav_milter

## Limitations

Formal support currently covers Puppet 8 on Ubuntu 24.04, Debian 12, and
AlmaLinux 9. These combinations are declared in `metadata.json` and have
automated catalog and runtime acceptance evidence.

Older platforms retained in characterization tests are catalog-compatible
legacy evidence, not maintained runtime-support claims. OpenVox 8 is
source/catalog tested but has not been agent-runtime tested. ClamAV 1.5+ is
runtime tested only with Ubuntu 24.04 distribution packages; this does not
establish a general upstream-package or cross-platform version claim. EPEL 9
runtime currently supplies ClamAV 1.4.x, while the official 1.5 RPM lacks the
package-native service and account integration required for an Enterprise
Linux claim. Ubuntu 26.04, Debian 13, and EL10 are not formally supported.

See the [support policy and evidence matrix](docs/support-policy.md) for the
meaning of each evidence level, legacy-removal policy, and links to the
relevant workflows and investigations.

## Development

Use the repository's Bundler environment:

```shell
bundle exec rake validate
bundle exec rake spec
```

GitHub Actions is the authoritative CI service. Its main workflow runs five
Ruby 3.3 jobs:

* Metadata, Puppet syntax, Hiera, and Ruby style validation.
* A focused compatibility suite for configuration precedence and
  platform-sensitive behavior.
* The complete unit suite across the operating systems declared in metadata.
* The complete unit suite with OpenVox 8 selected as the runtime.
* Catalog integration with the pinned `puppet/epel` 5.0.0 fixture for EL7.9
  and EL9.

The separate runtime-acceptance workflow exercises four Litmus targets. See
[development and CI](docs/development.md) for the supported local toolchain,
dependency rationale, commands, and the boundary between catalog and runtime
evidence.

The EPEL catalog coverage verifies relationships, repository resources, and
signing-key resources. It is not a package-installation acceptance test.

Pull requests should describe the affected operating systems, Puppet and
ClamAV versions, compatibility impact, and tests run.

### Puppet and OpenVox

The module uses one source tree for Puppet and OpenVox. Puppet 8 has catalog
and runtime CI coverage; OpenVox 8 currently has dependency-resolution,
metadata-validation, and catalog coverage. OpenVox runtime support is not yet
formally claimed. See [the dual-runtime support strategy](docs/openvox-support.md)
for the evidence requirements and publishing recommendation.

### Runtime acceptance

The Litmus CI suite provisions the `smoke`, `ubuntu-2404`, `debian-12`, and
`alma-9` targets from `provision.yaml`, installs Puppet 8 and this module,
applies the ClamAV manifest twice, and
checks packages, generated configuration, permissions, explicit stopped-service
policy, database directories, and native configuration parsing. Evidence is emitted with the
`CLAMAV_ACCEPTANCE_EVIDENCE` prefix so CI logs record the tested Puppet,
operating-system, ClamAV, and database state.

Run the complete workflow locally with Docker:

```shell
bundle exec rake spec_prep
bundle exec rake 'litmus:provision_list[smoke]'
bundle exec rake 'litmus:install_agent[puppet8]'
bundle exec rake litmus:install_module
bundle exec rake litmus:acceptance:parallel
bundle exec rake litmus:tear_down
```

Always tear down the target when debugging interrupts the sequence. The smoke
target demonstrates the harness; it does not add a runtime support claim.
It keeps daemons stopped so platform-specific service startup and runtime-directory
requirements can be characterized without folding new platform behavior into the
harness issue. Platform-specific acceptance and support decisions remain separate work.

Use `ubuntu-2404` instead of `smoke` in the commands above to exercise formally
supported Ubuntu 24.04 package versions, including a required ClamAV 1.5-or-newer
version assertion and Ubuntu package provenance. The target validates direct
services, native configuration parsing, runtime and database directories,
official database updates, systemd unit paths, opt-in socket activation, a
deterministic local test signature, and two-run convergence. It also exercises
caller-enabled `FIPSCryptoHashLimits` for both clamd and freshclam, records the
target's kernel FIPS state, and verifies detached CVD signatures. This proves
the opt-in ClamAV behavior, not that the ordinary CI container is FIPS-enabled.
See the [ClamAV 1.5 FIPS characterization](docs/clamav-1.5-fips.md).
Fresh database bootstrap, subsequent current-database checks, native signature
inspection, ownership, and clamd notification are described in the
[freshclam and database characterization](docs/clamav-1.5-freshclam-databases.md).

Use `debian-12` to exercise formally supported Debian 12. The target records its
package and ClamAV versions independently and checks configuration rendering,
database updates, direct services, opt-in socket activation, runtime paths,
test-file detection, and two-run convergence.

A `debian-13` provisioning entry and release-aware acceptance assertions are
available for continued investigation, but Debian 13 is not in the required CI
matrix and is not a claimed runtime target. As of July 2026, the Puppet agent
installer requests `puppet8-release-trixie.deb`, which is unavailable from the
Puppet package repository. Do not substitute Debian 12 agent packages or infer
Debian 13 support from container provisioning alone.

Use `alma-9` to exercise formally supported AlmaLinux 9 with the module-managed
EPEL repository. The target records the distribution, enabled repository,
package provenance, ClamAV, binary and unit paths, and SELinux state while
asserting that the current EPEL package remains below 1.5 and checking database updates,
`clamd@scan`, freshclam, runtime paths, test-file detection, and two-run
convergence. This evidence applies specifically to AlmaLinux 9 and does not
imply EL10 or Enterprise Linux ClamAV 1.5 support. See the
[Enterprise Linux 1.5 investigation](docs/clamav-1.5-enterprise-linux.md).
