# Optional AppArmor integration

AppArmor management is **disabled by default**. `manage_apparmor => false`
means policy remains outside module ownership: no fragments, loaders, cleanup,
or automatic warnings are introduced. A caller may already supply equivalent
policy externally, so the module does not reject this combination.

On Ubuntu 24.04 with enforced package profiles, native Freshclam and clamd
configuration validation requires read access to Puppet's temporary siblings.
Enable module policy ownership explicitly when managing these components:

```yaml
clamav::manage_apparmor: true
clamav::manage_freshclam: true
clamav::manage_clamd: true
clamav::validate_configs: true
```

Enabling validation alone does not enable AppArmor management. Conversely,
AppArmor management does not enable the host's AppArmor subsystem. The parser,
securityfs interface, and package profiles must be available to root.

## Native validation on Ubuntu 24.04

Puppet's native `File` resource writes candidate content to a temporary sibling,
validates it, and only then replaces the live configuration. The packaged
profiles allow the final config filename but deny sibling candidates. Their
validators report a generic “Can't open/parse” error even for valid content.
Moving candidates to `/tmp` does not fix the Freshclam policy restriction.

When `manage_apparmor`, `validate_configs`, and the corresponding component's
management switch are true on Ubuntu 24.04, the module generates:

| Validator | Local fragment | Default generated rule |
| --- | --- | --- |
| `/usr/bin/freshclam` | `/etc/apparmor.d/local/usr.bin.freshclam` | `"/etc/clamav/freshclam.conf*" r,` |
| `/usr/sbin/clamd` | `/etc/apparmor.d/local/usr.sbin.clamd` | `"/etc/clamav/clamd.conf*" r,` |

The literal prefix follows `freshclam_config` or `clamd_config`. The suffix
wildcard covers Puppet's undelimited temporary names and other same-prefix
siblings; it cannot traverse directories and grants no write access. Config
paths may contain ASCII letters, digits, spaces, `/`, `_`, `.`, and `-`.
Policy metacharacters and `.`/`..` path components are rejected, not interpolated
into policy. Parent directories must exist; module-managed parents are ordered
before policy probing.

For each validator the resource order is:

```text
package and config-directory prerequisites
  -> local profile fragment
  ~> targeted parent-profile reload
  -> policy readiness check/recovery
  -> native File[<validator>.conf] validation and replacement
  ~> existing service subscription
```

The module reloads the complete corresponding parent under `/etc/apparmor.d/`,
which must include its matching `local/` fragment. Package-owned profiles are
not modified. Reload failure blocks configuration replacement. Precise resource
edges avoid a dependency cycle through the component's package or service.

The shared `/usr/local/sbin/clamav-apparmor` helper accepts only the reviewed
Freshclam and clamd mappings. It checks that the expected profile is loaded
and that the native binary can parse a fixed, harmless `LogSyslog false` config
in an exclusively created sibling. It removes that probe on exit, never copies
live content, and does not replace Puppet's actual config validation. Loaded
complain mode is recognized without asserting enforcement; enforcing runtime
tests check enforce mode separately.

Fragment, helper, and package changes trigger reload. A separate guarded check
repairs missing or stale loaded policy without waiting for a file-change event.
Per-validator root-only retry flags named
`/etc/apparmor.d/local/.clamav-<validator>-reload-pending` preserve failed reloads
(including caller-rule changes). A flag is removed only after loading and probing
succeed; its absence is not proof of current kernel policy. Healthy repeat applies
check readiness but do not reload. Recovery from stale policy can itself produce
an audit denial on the helper's initial probe.

On upgrade the obsolete module-owned
`/usr/local/sbin/clamav-freshclam-apparmor` is removed when automatic validation
support is active. Freshclam's existing retry flag is reused. No top-level
public parameter changes are required; the original internal `freshclam_config`
argument remains a compatibility alias. Turning management off does not remove
previously installed policy or helpers; arrange deliberate cleanup externally.

Overridden validation commands remain unchanged. The helper checks the packaged
`/usr/bin/freshclam` and `/usr/sbin/clamd` binaries, not arbitrary overridden
executables. Alternate packages or site profiles need their own policy review.
Other platforms retain the caller-supplied-file API with no automatic loader.

## Caller-supplied fragments

`apparmor_profiles` still accepts `path`, `content`, and `ensure` entries.
Unrelated entries retain the existing full-file management behavior; their
loading remains caller responsibility. For either generated validation fragment,
the module preserves caller content and appends its narrow generated rule in
one File resource. For example:

```puppet
class { 'clamav':
  manage_apparmor => true,
  manage_clamd    => true,
  apparmor_profiles => [{
    'path'    => '/etc/apparmor.d/local/usr.sbin.clamd',
    'content' => "  /srv/clamav/database/ r,\n",
    'ensure'  => 'present',
  }],
}
```

The entire local file is managed: transfer any existing unmanaged rules into
`apparmor_profiles` before opting in. Duplicate entries for an automatically
managed profile and `ensure => absent` conflicts fail compilation. Do not declare
a competing File resource. Unmanaged site policy and broader path permissions
are not inferred from config values.

## Complete native-validator inventory

All four native validators remain enabled when the component is managed and
`validate_configs` is true, on supported module platforms. Direct
`clamav::clamonacc` declarations use its `validate_config` switch. The default
commands below are all overridable.

| Resource | Config path parameter / Ubuntu path | Default command | Ubuntu package policy and action |
| --- | --- | --- | --- |
| `File[clamd.conf]` | `clamd_config` / `/etc/clamav/clamd.conf` | `/usr/bin/env clamd --config-file % --version` | Confined; candidate denial confirmed; manage local rule |
| `File[freshclam.conf]` | `freshclam_config` / `/etc/clamav/freshclam.conf` | `/usr/bin/env freshclam --config-file % --version` | Confined; candidate denial confirmed; manage local rule |
| `File[clamav-milter.conf]` | `clamav_milter_config` / caller-supplied Ubuntu integration | `/usr/bin/env clamav-milter --config-file % --version` | No matching package profile; no speculative rule |
| `File[clamonacc.conf]` | `clamonacc_config` / `/etc/clamav/clamonacc.conf` | `/usr/bin/env clamonacc --config-file % --help` | No matching package profile; no speculative rule |

Inspected [Ubuntu Noble ClamAV packaging source](https://archive.ubuntu.com/ubuntu/pool/main/c/clamav/clamav_1.5.3+dfsg-0ubuntu0.24.04.1.debian.tar.xz),
version `1.5.3+dfsg-0ubuntu0.24.04.1`, SHA256
`e8b9c27371ad564b1a707c6a35d70be6c3944d8eadb0633e2e9c5757fdddc85d`.
`debian/rules`, the package install manifests, `debian/usr.bin.freshclam`, and
`debian/usr.sbin.clamd` establish both exact-path allowances and local includes.
The same source installs `/usr/sbin/clamonacc` and `/usr/sbin/clamav-milter`
without profiles for either binary. The Noble
[apparmor-profiles](https://packages.ubuntu.com/noble/all/apparmor-profiles/filelist)
and [apparmor-profiles-extra](https://packages.ubuntu.com/noble/all/apparmor-profiles-extra/filelist)
inventories likewise supply neither attachment. These findings describe package
policy, not arbitrary site-installed policy or confinement inherited from another
program. Inspect loaded policy when using custom deployments.

## Enforcing acceptance

On a disposable Ubuntu 24.04 Litmus target with policy administration and kernel
journal access, run `spec/acceptance/apparmor_validation_spec.rb` with
`CLAMAV_APPARMOR_ACCEPTANCE=1` in the runner environment. This destructive test
installs packages and replaces both local fragments and configurations; never
select a production target. It verifies both original denials, then real Puppet
content changes, candidate reads, invalid-config rejection, active services,
unchanged package profiles, obsolete helper removal, stale-policy recovery, and
second-run convergence. Opted-in runs fail if profiles are not enforced.

The standard Docker acceptance matrix does not enable this test. Catalog and
helper subprocess tests do not establish kernel enforcement. Report those
results separately from an opted-in enforcing run or a production canary.
