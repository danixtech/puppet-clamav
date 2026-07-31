# Optional AppArmor integration

AppArmor integration is disabled by default. When enabled, the module manages
only caller-supplied local profile files or profile fragments:

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

The module does not replace distro profiles, enable AppArmor, invent policy,
or run a parser/reload command automatically. The caller or distribution must
load/reload the profile using its supported local-override mechanism. Profile
content and policy type compatibility remain caller responsibility.

This interface is intended for custom runtime, database, log, socket-parent,
temporary, and quarantine paths. Default catalogs remain unchanged, and
Debian/Ubuntu package profiles remain distro-owned unless a caller explicitly
manages a local file.
