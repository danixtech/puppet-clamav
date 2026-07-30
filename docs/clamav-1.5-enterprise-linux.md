# ClamAV 1.5 on Enterprise Linux

Status: blocked for a supported standalone-module path

Evidence collected: 2026-07-30

Issue #12 compared the maintained EPEL packaging path with the official ClamAV
1.5.3 RPM and the custom-unit workaround used by a downstream control profile.
The result does not justify changing module defaults or claiming Enterprise
Linux ClamAV 1.5 support.

## Supported packaging baseline

The required AlmaLinux 9 acceptance target installs ClamAV from EPEL using the
module's existing `puppet/epel` integration. The exact tested package is emitted
in every workflow run. At this checkpoint it is `1.4.5-2.el9`.

This path is operationally complete:

- EPEL supplies split `clamav`, `clamd`, and `clamav-freshclam` packages;
- binaries use `/usr/bin` and `/usr/sbin`;
- packages create the `clamscan` and `clamupdate` accounts;
- package-native `clamd@.service` and `clamav-freshclam.service` units are used;
- configuration lives under `/etc`;
- databases live under `/var/lib/clamav`;
- native parsing, freshclam updates, services, socket permissions, signature
  detection, and two-run convergence are required runtime checks.

The acceptance target deliberately asserts that this package remains older
than 1.5. This turns a future EPEL version transition into a visible evidence
review instead of silently extending the version claim.

The current Fedora package index lists 1.4.x for EPEL 9 and EPEL 10:
<https://packages.fedoraproject.org/pkgs/clamav/clamav/>.

## Official ClamAV 1.5.3 RPM inspection

Cisco-Talos publishes `clamav-1.5.3.linux.x86_64.rpm` and a detached signature
with the 1.5.3 release:
<https://github.com/Cisco-Talos/clamav/releases/tag/clamav-1.5.3>.

The RPM was inspected read-only in a disposable AlmaLinux 9 container. Its
observed interface differs materially from EPEL:

| Area | EPEL 9 | Official 1.5.3 RPM |
| --- | --- | --- |
| Trust/install source | Signed repository packages managed by DNF | Downloaded release asset with a detached signature; RPM header reports `Signature: (none)` |
| Package layout | Multiple component packages and virtual capabilities | One monolithic `clamav-1.5.3-1` RPM |
| Prefix | `/usr`, `/etc`, `/var` | Relocatable `/usr/local` |
| clamd | `/usr/sbin/clamd` | `/usr/local/sbin/clamd` |
| freshclam | `/usr/bin/freshclam` | `/usr/local/bin/freshclam` |
| Configuration | Active package configuration under `/etc` | Samples under `/usr/local/etc` |
| Accounts/directories | Package-managed | No account or directory scriptlets |
| systemd integration | Package-native clamd/freshclam units | No service, socket, tmpfiles, or sysusers files |
| RPM dependencies | Distribution dependency graph | Only `rpmlib(...)` capabilities were declared |

Digest verification passed, but digest integrity is not repository trust or
publisher authentication. The detached signature requires an external key
verification and artifact-promotion policy that does not belong in this
client module.

## Downstream custom-unit comparison

The read-only control profile removes the EPEL daemon/updater packages when
using an upstream RPM, then supplies local `clamd@.service` and
`clamav-freshclam.service` files and runs `systemctl daemon-reload`. That is a
site packaging workaround, not a reusable default:

- it assumes an externally trusted and distributed RPM;
- it replaces package-native unit ownership;
- it embeds local service policy and path assumptions;
- it must also solve accounts, writable directories, logs, and upgrades.

The standalone module should continue preferring package-native units. A
future custom-package mechanism must be optional and should accept explicit
package, binary, configuration, unit, account, and directory policy rather
than recognizing a special vendor RPM.

## Blockers and decision

There is no currently validated Enterprise Linux ClamAV 1.5 path suitable for
a formal module claim:

1. maintained EPEL 9/10 packaging remains on ClamAV 1.4.x;
2. the official 1.5.3 RPM is not repository-integrated and lacks native
   accounts, directories, configuration, and services;
3. package trust and detached-signature verification are external policy;
4. importing downstream custom units would make the module own vendor/package
   integration it cannot safely generalize;
5. EL10 still has separate repository-dependency and package-name blockers;
6. FIPS behavior remains issue #13 and must not be inferred from this work.

No module defaults, service resources, or support metadata change in issue
#12. Revisit this decision when a maintained EL repository publishes ClamAV
1.5+, or through a separate design issue for an explicit custom-package
interface with reproducible trust and runtime tests.
