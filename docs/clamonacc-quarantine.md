# clamonacc quarantine and runtime-directory design

This module uses ClamAV's native quarantine action. It does not parse log
messages or interpolate detected paths into shell commands.

## Supported mechanism

Quarantine is disabled by default. When all of the following are explicitly
configured, the module:

1. manages the quarantine directory with caller-selected ownership and mode;
2. requires that directory to be excluded from on-access scanning; and
3. adds `--move=<directory>` to the module-managed clamonacc unit.

```puppet
class { 'clamav':
  manage_clamonacc              => true,
  clamonacc_binary              => '/usr/sbin/clamonacc',
  clamonacc_config              => '/etc/clamav/clamonacc.conf',
  clamonacc_service             => 'clamav-onaccess',
  clamonacc_manage_service_unit => true,
  clamonacc_service_unit_path   => '/etc/systemd/system/clamav-onaccess.service',
  clamonacc_include_paths       => ['/srv/data'],
  clamonacc_exclude_paths       => ['/srv/quarantine'],
  clamonacc_manage_quarantine   => true,
  clamonacc_quarantine_path     => '/srv/quarantine',
  clamonacc_quarantine_owner    => 'root',
  clamonacc_quarantine_group    => 'security',
  clamonacc_quarantine_mode     => '0750',
}
```

Package-native units are not rewritten or overridden. Native quarantine is
therefore currently supported only with the explicitly managed unit, where
the module can prove the action is present. A caller using a package-native
unit may manage its own drop-in, but that behavior is outside this module's
current contract.

## Native ClamAV behavior

ClamAV 1.5.3 exposes `--move=DIRECTORY` for clamonacc and implements the
action in its shared `common/actions.c` code. The implementation:

- opens the detected file rather than recovering a pathname from log text;
- rejects symlink traversal for destination creation;
- creates destination names exclusively with mode `0600` when a copy is
  required;
- uses the basename unchanged when available;
- resolves collisions with `.001` through `.999` suffixes;
- keeps the infected source when quarantine creation or copying fails; and
- logs move success and failure through clamonacc's normal output.

The module-owned unit sends that output to the systemd journal. Retention and
forwarding remain system policy.

A same-filesystem move can retain filesystem metadata through rename/link
operations. A cross-filesystem move necessarily copies content and then
removes the source, so callers must not assume all original metadata is
preserved. Forensic workflows should collect required metadata before or
alongside quarantine.

## Permission policy

The default managed quarantine mode is `0700`, owned by `root:root`. This is a
safe default for the module-owned unit, which follows upstream's requirement
to run clamonacc with privileges sufficient for fanotify. Callers may select a
different owner, group, or mode, but must ensure the service can create files
in the directory.

The module can separately manage the configured temporary directory through
`clamonacc_manage_temporary_directory`. This is also opt-in because distro
packages may already own their runtime paths. Its default managed mode is
`0750`, owned by `root:root`, and all values are caller-overridable.

SELinux labels, AppArmor rules, tmpfiles, mount policy, retention, release
workflows, and quarantine restoration are intentionally outside this issue.
Those need platform-specific evidence and policy.

## Rejected design

The control-repository watcher tails a log, extracts text with `awk`, and
passes the resulting path to `mv`. That pattern is not included here because
log text is not a safe command channel, events can race with filesystem
changes, duplicate basenames need explicit handling, and failures are
difficult to audit reliably.

## Evidence boundary

Acceptance tests exercise the same native ClamAV action implementation using
EICAR content. They cover unusual filenames, duplicate basenames, restrictive
directory permissions, failure behavior, and idempotent Puppet directory
management.

Full fanotify-driven clamonacc detection, include/exclude behavior, and
platform support claims remain gated by modernization issue #19.
