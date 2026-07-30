# Support policy and evidence matrix

The module separates formal runtime support from source compatibility and
catalog characterization. `metadata.json` lists only the operating systems
and Puppet major version that are maintained as formal support claims.

## Evidence levels

| Level | Meaning |
| --- | --- |
| Formally supported | Declared in metadata, catalog tested, and exercised by required runtime acceptance on the named operating system and Puppet runtime. |
| Source/catalog tested | Dependency resolution, validation, and catalog compilation pass, but no agent has applied the module on the stated runtime/platform combination. |
| Legacy characterized | Compatibility tests preserve known historical behavior, but package availability and service behavior are not maintained with runtime acceptance. |
| Provisional | Investigation or an optional test target exists, but a known blocker or incomplete evidence prevents a support claim. |
| Unsupported | No maintained evidence exists. |

Catalog compilation alone never establishes package availability, native
configuration validity, service startup, database updates, permissions, or
idempotency.

## Formal support

| Puppet runtime | Operating system | Catalog tested | Runtime tested | Evidence |
| --- | --- | --- | --- | --- |
| Puppet 8 | Ubuntu 24.04 | Yes | Yes | Main CI plus the required `ubuntu-2404` Litmus job |
| Puppet 8 | Debian 12 | Yes | Yes | Main CI plus the required `debian-12` Litmus job |
| Puppet 8 | AlmaLinux 9 | Yes | Yes | Main CI plus the required `alma-9` Litmus job using module-managed EPEL |

The required runtime workflow installs packages, applies the catalog twice,
parses generated configuration with installed ClamAV binaries, exercises
database updates and deterministic test-signature detection, and checks
platform-specific services, paths, and permissions.

The exact ClamAV package version is emitted by each acceptance job. Formal OS
support does not imply support for a newer ClamAV release that is unavailable
from that platform's tested repositories.

## ClamAV version-specific runtime evidence

| ClamAV release | Operating system | Package source | Runtime evidence | Claim |
| --- | --- | --- | --- | --- |
| 1.5+ | Ubuntu 24.04 | Ubuntu archive/security package carrying an Ubuntu version suffix | Required `ubuntu-2404` acceptance asserts the installed version is at least 1.5, validates both generated configurations natively, starts direct services, exercises socket activation and signature detection, updates official databases, and proves two-run convergence | Formally runtime tested on this distribution/package combination |

This claim is deliberately narrower than general ClamAV 1.5 support. It does
not cover upstream binary packages, other Debian-family releases, a formally
FIPS-enabled runtime, clamonacc, or future directives merely because their
version number is newer.
The acceptance log records `apt-cache policy`, source-package identity, exact
binary package versions, service-unit paths, database files, and the installed
daemon version so repository or packaging changes remain reviewable.

## Source and catalog compatibility

| Runtime/platform | Evidence level | Current evidence | Missing release gate |
| --- | --- | --- | --- |
| OpenVox 8 | Source/catalog tested | Runtime selection is asserted before metadata validation and the complete unit suite | Install an OpenVox agent and pass required runtime acceptance on every claimed OS |
| Red Hat 9 | Source/catalog tested | Real `puppet/epel` 5.0.0 catalog integration plus AlmaLinux 9 runtime evidence for the equivalent EPEL package layout | Runtime evidence on RHEL itself |
| EL7 and EL8 families | Legacy characterized | Package names, EPEL resources, cron/service policy, paths, and relationships remain in unit tests | Maintained repositories and runtime acceptance on each named distribution |
| Debian 8, 9, and 11 | Legacy characterized | Historical package, path, ownership, and direct-service catalogs | Maintained package/runtime acceptance |
| Ubuntu 14.04 through 22.04 | Legacy characterized | Historical package, path, ownership, and direct-service catalogs | Maintained package/runtime acceptance |

Legacy characterization protects existing consumers from accidental semantic
changes. It is not a commitment to repair distribution repositories, agent
installation, or ClamAV packaging on end-of-life platforms.

## Provisional and unsupported targets

| Target | Status | Reason |
| --- | --- | --- |
| Debian 13 | Provisional | Acceptance assertions exist, but the Puppet 8 installer cannot obtain the expected Debian 13 agent repository package |
| EL10 | Provisional | ClamAV package names and freshclam service behavior differ; the current EPEL module dependency does not provide a compatible Puppet 8/EL10 path |
| OpenVox 8 agents | Provisional | Catalog compatibility is proven, but there is no agent-runtime acceptance matrix |
| ClamAV 1.5+ outside Ubuntu 24.04 distro packaging | Unsupported as a version claim | EPEL 9/10 remains on 1.4.x; the official RPM lacks repository, account, directory, configuration, and systemd integration |
| Ubuntu 26.04 | Unsupported | No catalog or runtime evidence |

See [the OpenVox strategy](openvox-support.md), the
[EL10 investigation](el10-investigation.md), and the
[Enterprise Linux ClamAV 1.5 investigation](clamav-1.5-enterprise-linux.md).
The [ClamAV 1.5 FIPS characterization](clamav-1.5-fips.md) documents the
caller-controlled FIPS-limits mechanism and its remaining runtime evidence
gate. The [freshclam and database characterization](clamav-1.5-freshclam-databases.md)
records update, ownership, signature, mirror, and daemon-notification behavior.

## Removing or adding a support claim

A formal row may be added only when:

1. metadata and platform data represent the actual package and service layout;
2. the complete catalog suite passes on each declared runtime;
3. required acceptance installs the runtime and packages on the named OS;
4. native configuration parsing, services, database updates, permissions,
   detection, and two-run convergence pass; and
5. the README and this matrix are updated in the same review.

A formal row may be removed when the operating system or runtime is
end-of-life, required repositories cease to function, or maintained acceptance
can no longer run. Removal is a support-policy change and must be called out in
release notes. Characterization tests should remain when they continue to
protect public parameters, lookup keys, option precedence, package naming, or
service semantics without imposing unmaintainable fixtures.

## Authoritative automation

The [main GitHub Actions workflow](../.github/workflows/ci.yml) provides
validation, lint, Puppet 8 and OpenVox 8 catalogs, focused compatibility
checks, and real legacy EPEL catalog integration. The
[runtime-acceptance workflow](../.github/workflows/acceptance.yml) provides the
formal OS evidence. The workflow definitions and their required status checks
are authoritative; a one-off local run does not expand the published support
matrix.
