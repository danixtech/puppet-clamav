clamav
=============

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

The clamav module provides some classes to install and configure most of the components of clamav.  
You may also choose to manage only the parts that you need.  
This module aims to be minimalistic.  
The module supplies baseline configuration defaults that can be overridden with class parameters or Hiera data.

This module has the following components that can be managed (or not):
* Base clamav package - command line and libs
* clamav user
* clam daemon
* freshclam daemon/cron (dependent on OS)
* clamav-milter

## Setup

### What clamav affects

* clamav/clamd/freshclam package install
* clamav/clamd/freshclam config files
* clamd/freshclam services or daily cron on redhat
* clamav-milter package install, config files, service (optional)
* clam user/group (optional)

### Setup Requirements

only need to install the module

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

### Add clamav-milter support and customize its config

Test milter socket choices on the target distribution before deployment.

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

### clamd option precedence

`clamd.conf` is generated from four option layers, with later layers taking
precedence:

1. Module baseline options.
2. OS-specific `clamav::clamd_platform_options` data.
3. `clamav::clamd_default_options` supplied by the caller.
4. `clamav::clamd_options` supplied by the caller.

Use `clamd_options` for normal overrides. Set a key to `undef` to omit that
directive. Boolean values render as `yes` or `no`; arrays render the directive
once per non-empty element. Empty strings and empty arrays emit no directive.
The legacy internal Hiera keys `clamav::os_clamd_defaults` and
`clamav::clamd_defaults_options` remain accepted, but new platform data should
use `clamav::clamd_platform_options`.

## Reference

### Classes

* clamav
* clamav::user
* clamav::clamd
* clamav::freshclam
* clamav::clamav_milter

## Limitations

The supported Puppet range is declared in `metadata.json`. Puppet versions outside that range are not supported.

The operating systems and releases supported by the published module are declared in `metadata.json`. Data files for additional releases may represent work in progress rather than a tested support commitment.

ClamAV 1.5.x support is not yet validated by this module's test suite. Test package availability, configuration directives, database updates, and service startup before deploying it.

## Development

Run `bundle exec rake validate` and `bundle exec rake spec` before opening a pull request. Include the affected Puppet, operating-system, and ClamAV versions in the pull request description.
