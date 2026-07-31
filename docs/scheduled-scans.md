# Optional scheduled scans

Scheduled scans are disabled by default. The `scheduled_scans` parameter
accepts typed definitions for a systemd timer and oneshot service:

```puppet
class { 'clamav':
  scheduled_scans => [{
    'name'            => 'daily',
    'schedule'        => '*-*-* 02:00:00',
    'paths'           => ['/home'],
    'excludes'        => ['/home/cache'],
    'scanner'         => 'clamscan',
    'user'            => 'clamav',
    'log'             => '/var/log/clamav/daily.log',
    'quarantine_path' => '/srv/quarantine',
  }],
}
```

The module validates absolute, shell-safe paths and creates a service/timer
pair under `/etc/systemd/system`. It does not invent schedules, scan paths,
email policy, or site directories. `clamscan` and `clamdscan` are explicit
choices; quarantine uses the native `--move` action. Directory ownership and
SELinux/AppArmor policy remain separate caller-managed concerns.

The feature is currently validated at catalog/runtime workflow level; callers
must verify scanner availability, scan duration, storage, and quarantine
retention for their platform before enabling a schedule.
