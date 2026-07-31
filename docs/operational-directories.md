# Optional operational directories

The `managed_directories` parameter provides an explicit, typed directory
mechanism for custom ClamAV paths. Each entry contains an absolute `path` and
optional `owner`, `group`, and `mode` values:

```puppet
class { 'clamav':
  managed_directories => [{
    'path'  => '/srv/clamav/run',
    'owner' => 'clamav',
    'group' => 'clamav',
    'mode'  => '0750',
  }],
}
```

Management is opt-in. The module does not infer parent directories, recurse,
purge content, or claim distro defaults such as `/run/clamav`,
`/var/lib/clamav`, `/var/log/clamav`, `/etc`, or `/tmp`. If a caller lists a
package-managed path, Puppet becomes authoritative for that directory's
declared attributes.

Existing clamonacc quarantine and temporary-directory parameters remain
unchanged and are not duplicated by this interface. SELinux, AppArmor, socket
permission migration, and systemd hardening are separate follow-up work.
