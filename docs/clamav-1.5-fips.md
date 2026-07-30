# ClamAV 1.5 FIPS characterization

ClamAV 1.5 adds `FIPSCryptoHashLimits` to clamd and freshclam. The option
disables MD5 and SHA-1 for trust decisions, disables MD5/SHA-1 false-positive
signatures, and requires detached `.sign` files when verifying official CVD
databases. ClamAV 1.5 also attempts to detect system FIPS mode and enables
these limits automatically when it does.

This module does not manage host FIPS mode. It also does not enable
`FIPSCryptoHashLimits` by default. A caller that has established a ClamAV 1.5
runtime may opt in for both components:

```puppet
class { 'clamav':
  manage_clamd     => true,
  manage_freshclam => true,
  clamd_options => {
    'FIPSCryptoHashLimits' => true,
  },
  freshclam_options => {
    'FIPSCryptoHashLimits' => true,
  },
}
```

Setting only one component is incomplete policy: clamd loads and trusts the
databases, while freshclam downloads and verifies them.

## Evidence matrix

| Platform and runtime | FIPS state | Configuration and service evidence | Database and scan evidence | Result |
| --- | --- | --- | --- | --- |
| Ubuntu 24.04.4 production host; ClamAV 1.5.3, FLEVEL 233; `6.8.0-134-fips` kernel | The FIPS kernel was recorded, but the authoritative `/proc/sys/crypto/fips_enabled` value was not retained | The module-generated clamd and freshclam configurations parsed; both services refreshed and remained healthy | Existing production databases remained usable | Compatible evidence, but insufficient to claim a specifically FIPS-enabled runtime |
| Ubuntu 24.04 required acceptance; Ubuntu ClamAV 1.5+ package | The job records `/proc/sys/crypto/fips_enabled`; ordinary GitHub-hosted containers are expected to report disabled or unavailable | Both generated configurations explicitly enable `FIPSCryptoHashLimits`; native validation, clamd startup, and freshclam startup pass | Freshclam updates official databases, versioned detached `main-<version>.cvd.sign` and `daily-<version>.cvd.sign` files are present, and the deterministic EICAR scan passes | Required opt-in behavior is runtime tested; this is not a host-FIPS claim |
| AlmaLinux 9 required acceptance; EPEL ClamAV 1.4.x | SELinux state is recorded; no FIPS-enabled target is provisioned | ClamAV 1.5 and `FIPSCryptoHashLimits` are unavailable through the tested EPEL path | Existing pre-1.5 database update and scan coverage passes | No Enterprise Linux ClamAV 1.5/FIPS claim |
| Official Cisco ClamAV 1.5.3 EL RPM | Not installed because the package is not a viable standalone module default | The RPM lacks distro accounts, systemd units, sysusers, tmpfiles, and configuration integration | Not runtime tested | Blocked by the packaging findings in `clamav-1.5-enterprise-linux.md` |

## Compatibility decisions

- Do not infer enabled FIPS mode from a kernel name alone.
- Do not add a global or Ubuntu default. The option does not exist before
  ClamAV 1.5, and the module still supports older distribution packages.
- Preserve generic caller option hashes as the version-specific escape hatch.
  Both `true` and `false` render without hidden fact-based rewriting.
- Do not implement automatic Puppet-side FIPS detection. ClamAV 1.5 already
  performs runtime detection, while Puppet catalog facts can be absent or
  differ from the service's cryptographic environment.
- Treat the clamd and freshclam values as one operational policy.
- Do not claim Enterprise Linux ClamAV 1.5/FIPS support until a maintained
  packaging path and a genuinely FIPS-enabled runtime target both exist.

## Remaining evidence gate

A formal FIPS-enabled claim requires a reproducible target that records an
authoritative enabled state, then passes:

1. clamd and freshclam native configuration validation;
2. freshclam update with detached CVD signatures;
3. clamd startup and reload;
4. representative signature detection;
5. two-run Puppet convergence.

The current evidence justifies the caller-controlled mechanism and documents
its limits. It does not justify a new module default or metadata support claim.

## Sources

- ClamAV 1.5.3 `clamd.conf.sample`
- ClamAV 1.5.3 release notes
- Ubuntu 24.04 production-parity runtime evidence
- Required Ubuntu 24.04 and AlmaLinux 9 acceptance jobs
