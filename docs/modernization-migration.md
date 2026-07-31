# Modernization migration guide

This guide describes the operator-visible changes in the modernization line.
The branch preserves the existing default package, account, service, socket,
and option precedence policies unless a parameter is explicitly enabled.

## Before upgrading

1. Run the complete unit and acceptance matrix for the release candidate.
2. Record current `clamav`, `clamd`, and `freshclam` package versions and
   service names.
3. Review local Hiera for the public keys listed in the compatibility notes
   below, especially `clamd_default_options`, `clamd_options`, and
   `freshclam_options`.
4. For custom paths, verify that the package account can access every parent
   directory before enabling optional directory, SELinux, or AppArmor inputs.

## Compatibility-preserving defaults

The following remain unchanged unless explicitly configured:

- component package `ensure => latest` and component-specific version
  overrides;
- package-native users, groups, paths, and service units;
- direct-service clamd policy and `LocalSocketMode 666`;
- `manage_clamonacc => false` and no clamonacc resources by default;
- option-hash replacement semantics: omitting `clamd_default_options` uses the
  platform baseline, while supplying it replaces that baseline before
  `clamd_options` is applied;
- direct child-class declarations and public Hiera keys.

## Additive features

The following are opt-in and require no migration when unused:

- typed freshclam mirror policy;
- scheduled scan service/timer definitions;
- managed operational directories and explicitly listed log files;
- SELinux file contexts and AppArmor local profiles;
- clamonacc configuration, service, quarantine, and temporary-directory hooks.

These mechanisms do not infer parent directories, enable security policy,
rotate logs, publish databases, or replace distro package integration.

## Values requiring review

Constrained package/service/path types can reject values that previously
compiled but could not produce a valid catalog. Treat such failures as
configuration corrections: use absolute paths, valid file modes, supported
service ensure/enable values, and non-empty package/service names.

The migration does not silently change account UID/GID policy, package source,
socket permissions, or repository credentials. Cisco/Talos installer packages
remain an external integration concern.

## Rollback

Disable newly enabled optional parameters and redeploy the previous module
artifact. Do not delete custom directories or quarantine content as part of a
rollback; directory resources are non-purging and only manage paths explicitly
listed by the caller. Revert any separately managed SELinux/AppArmor policy
through the owning site profile.

## Semantic-version recommendation

The modernization work is predominantly additive and preserves default runtime
behavior. However, the constrained public types can turn previously accepted
invalid inputs into catalog compilation failures. If those constraints are
published together with the current API, release them as **4.0.0** from the
3.x metadata line and call out the validation tightening as a breaking change.

If maintainers split all stricter validation into a later release and prove
that this release contains only additive, opt-in behavior, a 3.1.0 release is
reasonable instead. Do not publish a minor release while changing defaults or
silently activating previously inert Hiera data.
