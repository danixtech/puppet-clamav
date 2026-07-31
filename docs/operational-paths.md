# Operational log and quarantine paths

The module provides two explicit mechanisms for operational paths:

- `managed_directories` creates caller-selected directories, including custom
  quarantine, runtime, database, and log directories.
- `managed_log_files` creates caller-selected empty log files with optional
  ownership and mode.

Neither mechanism infers parent directories, claims distro defaults, purges
content, or configures rotation/retention. Existing clamonacc quarantine and
temporary-directory parameters remain compatible and are not replaced.

```puppet
class { 'clamav':
  managed_directories => [{
    'path'  => '/srv/clamav/quarantine',
    'owner' => 'clamav',
    'group' => 'clamav',
    'mode'  => '0750',
  }],
  managed_log_files => [{
    'path'  => '/srv/clamav/logs/clamd.log',
    'owner' => 'clamav',
    'group' => 'clamav',
    'mode'  => '0640',
  }],
}
```

Rotation and retention are intentionally pluggable. Callers may use their
preferred logrotate or systemd-journald policy without a module dependency.
Scheduled scans, freshclam, milter, and clamonacc can all use these explicit
paths; the module does not parse log content or synchronize quarantine files.
