# Enterprise Linux 10 packaging investigation

Status: investigation complete; runtime support is not declared

Evidence collected: 2026-07-28

## Decision

Do not declare EL10 support or add EL10 defaults yet.

EPEL 10 now publishes ClamAV packages, but its package interface differs from
EL7 through EL9. The module's Red Hat defaults install the virtual capabilities
`clamav-scanner-systemd` and `clamav-update`. Neither capability is provided by
the probed EPEL 10 repositories. The corresponding EL10 package names are
`clamd` and `clamav-freshclam`.

Until EL10 defaults and runtime behavior are implemented and tested, callers
experimenting with EL10 must manage EPEL or another compatible repository
outside this module, set `manage_repo => false`, and explicitly override the
component package names.

## Repository findings

The investigation used a disposable AlmaLinux 10.2 container on aarch64.
AlmaLinux Extras supplied `epel-release-10-6.el10`, and CRB was enabled in the
base image. EPEL then supplied ClamAV 1.4.3 packages. EPEL is a moving
repository: the Fedora package index reported newer EPEL 10 builds when this
record was written, so the observed version is evidence rather than a pinned
module requirement.

The following repository strategies are viable:

| Strategy | Status | Module implications |
| --- | --- | --- |
| Distribution EPEL release package | Available on probed AlmaLinux 10.2 | Future runtime tests may use it, but must also verify CRB on each distribution |
| Externally managed EPEL | Safe interim strategy | Use `manage_repo => false` and explicit package overrides |
| `puppet/epel` 5.0.0 | Puppet 7/8 compatible, but declares only EL7-9 | Keep for existing supported platforms; do not use as EL10 evidence |
| `puppet/epel` 6.0.0 | Declares EL10, but requires OpenVox 8.19+ | Cannot satisfy this module's current Puppet-compatible dependency contract |
| Custom or upstream ClamAV RPMs | Technically possible, not standardized | Site policy; the standalone module should not ship custom units or repository trust |

Puppet Core currently lists RHEL 10 agent packages as supported. OpenVox also
publishes an OpenVox 8 EL10 repository. Those facts establish agent
availability, not compatibility of this module's current `puppet/epel`
dependency across both runtimes.

Sources:

- [Fedora ClamAV package index](https://packages.fedoraproject.org/pkgs/clamav/clamav/)
- [Puppet Core supported agent platforms](https://help.puppet.com/core/current/Content/PuppetCore/supported_operating_systems.htm)
- [Puppet Core repository instructions](https://help.puppet.com/core/current/Content/PuppetCore/enable_the_puppet_platform_repository.htm)
- [OpenVox 8 EL10 repository](https://yum.voxpupuli.org/openvox8/el/10/)
- [`puppet/epel` 6.0.0 metadata](https://github.com/voxpupuli/puppet-epel/blob/v6.0.0/metadata.json)
- [`puppet/epel` 5.0.0 metadata](https://github.com/voxpupuli/puppet-epel/blob/v5.0.0/metadata.json)

## Package and runtime mapping

| Component | EL10 observation |
| --- | --- |
| Scanner CLI | `clamav`; `/usr/bin/clamscan` |
| Daemon | `clamd`; `/usr/sbin/clamd` |
| Database updater | `clamav-freshclam`; `/usr/bin/freshclam` |
| Filesystem/accounts | `clamav-filesystem` |
| Daemon configuration | `/etc/clamd.d/scan.conf` |
| Freshclam configuration | `/etc/freshclam.conf` |
| Daemon service | `clamd@scan`, from `clamd@.service` |
| Freshclam service | `clamav-freshclam` |
| Freshclam timer alternative | `clamav-freshclam-once.timer` |
| Scanner account | `clamscan` |
| Database account | `clamupdate` |
| Database directory | `/var/lib/clamav` |
| Daemon runtime directory | `/run/clamd.scan`, created as `clamscan:virusgroup` |

The EL10 `clamav-freshclam` unit starts `freshclam -d --foreground=true`
directly. The package does not provide or consume `/etc/sysconfig/freshclam`.
The module's current Red Hat default would create that obsolete file.

## Current blockers

1. Default daemon and updater package names do not resolve on EL10.
2. The current `puppet/epel < 6.0.0` dependency has no declared EL10 support.
3. `puppet/epel` 6.0.0 is OpenVox-only metadata and cannot replace the current
   dependency while this module supports Puppet 8 from the same artifact.
4. The freshclam sysconfig default does not match the EL10 unit.
5. No EL10 systemd runtime, database update, scan, idempotency, or
   enforcing-SELinux evidence exists for this module.
6. CRB and EPEL enablement must be verified independently for RHEL, AlmaLinux,
   Rocky Linux, and Oracle Linux.

## Read-only acceptance prototype

The current public interface can compile a useful experimental catalog without
changing module defaults:

```puppet
class { 'clamav':
  manage_repo         => false,
  manage_clamd        => true,
  manage_freshclam    => true,
  clamd_package       => 'clamd',
  freshclam_package   => 'clamav-freshclam',
  freshclam_sysconfig => undef,
}
```

This is not a support claim. A future EL10 implementation must add
release-specific defaults and runtime acceptance that proves:

1. the selected external repository and its trust configuration;
2. package installation on each claimed distribution;
3. configuration parsing by the installed ClamAV version;
4. `clamd@scan` and freshclam startup;
5. database updates and deterministic malware-signature detection;
6. runtime directory and socket ownership;
7. two-run idempotency;
8. SELinux behavior on an enforcing host; and
9. Puppet 8 and OpenVox 8 agent execution where both are claimed.

The old modernization prototype's EL10 Hiera data is useful as a path/options
reference, but it does not address package capability removal, repository
dependency constraints, or runtime validation. It should not be copied as an
EL10 implementation.
