# Optional SELinux integration

SELinux integration is disabled by default. Enabling it is an explicit caller
choice and requires the external `puppet-selinux` module to be installed and
managed by the caller or environment.

```puppet
class { 'clamav':
  manage_selinux        => true,
  managed_directories   => [{
    'path'  => '/srv/clamav/quarantine',
    'owner' => 'clamav',
    'group' => 'clamav',
    'mode'  => '0750',
  }],
  selinux_file_contexts => [{
    'path'   => '/srv/clamav/quarantine',
    'type'   => 'antivirus_db_t',
    'ensure' => 'present',
  }],
  selinux_booleans      => [],
}
```

The module manages only the explicitly supplied file contexts and booleans;
it does not change SELinux enforcing/permissive mode, invent policy types, or
claim distro-default paths. The caller is responsible for selecting policy
types supported by the target SELinux policy and for installing
`puppet-selinux` when `manage_selinux` is enabled.

This interface is intended for custom runtime, database, log, socket-parent,
temporary, and quarantine paths created through `managed_directories`.
Enforcing-mode runtime validation remains platform-dependent and must be
performed before claiming support for a specific package/policy combination.
