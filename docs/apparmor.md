# Optional AppArmor integration

AppArmor integration is disabled by default. When enabled, the module manages
caller-supplied local profile files or profile fragments, plus the Ubuntu 24.04
Freshclam validation allowance described below:

```puppet
class { 'clamav':
  manage_apparmor   => true,
  apparmor_profiles => [{
    'path'    => '/etc/apparmor.d/local/usr.sbin.clamd',
    'content' => "  /srv/clamav/** r,\n",
    'ensure'  => 'present',
  }],
}
```

Outside the Freshclam exception below, the module does not replace distro
profiles, enable AppArmor, or run a parser/reload command automatically. The caller or distribution must
load/reload the profile using its supported local-override mechanism. Profile
content and policy type compatibility remain caller responsibility.

This interface is intended for custom runtime, database, log, socket-parent,
temporary, and quarantine paths. Default catalogs remain unchanged, and
Debian/Ubuntu package profiles remain distro-owned unless a caller explicitly
manages a local file.

## Freshclam validation on Ubuntu 24.04

With `manage_apparmor => true`, `manage_freshclam => true`, and
`validate_configs => true`, the module additionally manages
`/etc/apparmor.d/local/usr.bin.freshclam`. It grants read access to the configured
`freshclam_config` path plus a suffix wildcard, for example:

```text
"/etc/clamav/freshclam.conf*" r,
```

Puppet validates a temporary sibling before replacing the live file. Ubuntu's
exact-path package allowance does not cover that sibling. The suffix wildcard
covers Puppet's undelimited temporary names and other same-prefix files, but
never traverses directories or grants write access. Validation and atomic
replacement remain Puppet File operations.

The local fragment and package changes trigger a reload of the complete
`/etc/apparmor.d/usr.bin.freshclam` profile before configuration validation,
including the first apply. The package-owned file is not modified. A small
read probe detects a stale loaded candidate allowance and retries loading it
on later applies even if the local fragment has not changed. A root-only retry
flag in `/etc/apparmor.d/local/.clamav-freshclam-reload-pending` also preserves
failed refreshes involving caller rules; it is removed only after loading and
probing succeed, and is never used as proof of current kernel policy. The probe uses a
fixed valid configuration in an exclusively created sibling, removes it on
exit, and never copies or installs the live configuration. Successful steady
state applies do not reload policy. A failed read probe can itself produce an
AppArmor denial when recovering stale policy.

This exception requires the Ubuntu package layout, the AppArmor parser, and
the parent's `include <local/usr.bin.freshclam>` (optionally `if exists`).
AppArmor enablement remains caller responsibility. The helper always probes
`/usr/bin/freshclam`; overridden validators are preserved, but validators for
other confined executables need their own policy. Other platforms retain the
caller-supplied-file interface only. Users with `manage_apparmor => false`
receive no automatic rule or reload and must arrange policy externally.

The local file is fully managed. Preserve any existing local rules by supplying
them through the existing API; the module appends its generated rule:

```puppet
class { 'clamav':
  manage_apparmor   => true,
  apparmor_profiles => [{
    'path'    => '/etc/apparmor.d/local/usr.bin.freshclam',
    'content' => "  /srv/clamav/database/ r,\n",
    'ensure'  => 'present',
  }],
}
```

An `absent` entry for this file conflicts with enabled automatic validation
support and is rejected. Do not declare a second resource for the same file.
Custom config paths may contain ASCII letters, digits, spaces, `/`, `_`, `.`,
and `-`; policy metacharacters are rejected rather than treated as patterns.
The parent directory must exist before policy probing. Turning management off
does not remove previously installed files or unload policy; manage any desired
cleanup explicitly.

### Enforcing acceptance

On a disposable Ubuntu 24.04 Litmus target with kernel audit access and
permission to load AppArmor policy, run the dedicated
`spec/acceptance/freshclam_apparmor_spec.rb` with
`CLAMAV_APPARMOR_ACCEPTANCE=1` in the test runner environment. The test installs
packages and replaces the target's Freshclam local fragment/configuration;
never select a production target. It asserts enforcement and the original
negative reproduction, then exercises a real Puppet content change, manual
candidate reads, invalid configuration rejection, unchanged package profile,
stale-policy recovery, and second-run convergence. Missing enforcement is a
failure when opted in. The normal Docker matrix skips this test and does not
provide enforcing-mode evidence.
