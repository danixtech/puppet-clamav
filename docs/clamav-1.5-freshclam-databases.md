# ClamAV 1.5 freshclam and database behavior

Freshclam is the authority for downloading and verifying official ClamAV
databases. The module renders freshclam policy and manages the platform service;
it does not download databases with Puppet resources, replace ClamAV signature
verification, or publish a mirror.

## Runtime evidence

| Platform | ClamAV path | Bootstrap and subsequent run | Ownership and verification | clamd notification |
| --- | --- | --- | --- | --- |
| Ubuntu 24.04 | Ubuntu ClamAV 1.5+ packages | A stopped-service bootstrap downloads `main.cvd`, `daily.cvd`, bytecode data, and versioned detached `.cvd.sign` files. A subsequent run reports the databases are current. | Official databases are owned by `clamav`, are not group/world writable, and pass `sigtool --info` verification. | With caller-supplied `NotifyClamd /etc/clamav/clamd.conf`, deleting and re-fetching `daily.cvd` reports successful notification. clamd stays active with the same PID, demonstrating reload rather than restart. |
| Debian 12 | Distribution packages | Freshclam bootstraps official databases and a subsequent run reports them current. | Official CVD/CLD files are owned by `clamav`, are not group/world writable, and `main.cvd` passes native verification. | No module default is imposed; callers may use the platform clamd configuration path. |
| AlmaLinux 9 | EPEL ClamAV 1.4.x packages | Freshclam bootstraps official databases and a subsequent run reports them current. | Official CVD/CLD files are owned by `clamupdate`, are not group/world writable, and `main.cvd` passes native verification. | No module default is imposed. This evidence must not be treated as Enterprise Linux ClamAV 1.5 support. |

All three required targets also start their package-native freshclam services,
record exact freshclam versions, load the downloaded databases in clamd, detect
the deterministic test signature, and prove Puppet convergence.

## Mirror behavior

The existing `freshclam_options` hash is the public mechanism for native
freshclam mirror policy:

```puppet
class { 'clamav':
  manage_freshclam => true,
  freshclam_options => {
    'PrivateMirror' => [
      'mirror-a.example.test',
      'mirror-b.example.test',
    ],
    'DatabaseMirror' => 'database.clamav.net',
    'NotifyClamd'    => '/etc/clamav/clamd.conf',
  },
}
```

Repeated private mirrors retain caller order. A public `DatabaseMirror` may be
kept as a fallback when that is site policy. The module does not test or
rewrite private-mirror URLs, install private certificate authorities, or
assume that private mirrors carry detached ClamAV 1.5 signature files.

`PrivateMirror` changes freshclam's update source and trust boundary. Operators
must ensure that a chosen mirror publishes a complete, internally consistent
database set. When `FIPSCryptoHashLimits` is enabled, that includes the
versioned detached `.cvd.sign` files required for CVD verification.

## Notification behavior

`NotifyClamd` belongs to caller policy because configuration paths and daemon
topology can be site-specific. The Ubuntu 24.04 runtime target proves the
standard single-host path. The module intentionally does not infer a
notification path from `clamd_config` or add one globally; doing so would
silently change existing freshclam behavior and could target an unmanaged
daemon.

## Failure handling

- Candidate freshclam configuration is validated by the installed freshclam
  binary before Puppet replaces the live file.
- Freshclam itself owns download, DNS/CDN selection, incremental-update
  fallback, signature verification, and preservation/replacement of corrupt
  databases.
- A failed freshclam command or service is surfaced by its native exit status
  and logs. The module does not substitute an unsigned database.
- Mirror reachability, proxy/TLS policy, rate limiting, and private CA trust are
  deployment concerns and must be validated against the selected mirror.
- A running service alone is not sufficient evidence. Required acceptance
  checks database files, native signature information, ownership, update
  results, daemon loading/detection, and convergence.

## Compatibility decisions

- No package, service, mirror, notification, ownership, or permission default
  changes as part of this characterization.
- Existing option replacement and caller-override semantics remain unchanged.
- Detached `.cvd.sign` assertions apply only to the tested ClamAV 1.5 path.
- Server-side mirror publishing and scheduled scans remain out of scope.
