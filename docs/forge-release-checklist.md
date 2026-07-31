# Forge release checklist

This checklist prepares a release candidate without publishing it. The
modernization branch must pass the complete CI and runtime matrix before a
human performs the publication steps.

## Candidate gates

- `bundle exec rake validate`
- `bundle exec rake rubocop`
- `bundle exec rake spec`
- Puppet 8 and OpenVox 8 CI jobs
- Ubuntu 24.04, Debian 12, AlmaLinux 9, and smoke Litmus jobs
- `pdk build` (or the equivalent approved PDK build task)
- install the resulting tarball into a clean temporary module directory and
  rerun metadata/syntax validation

The package source is distribution-native ClamAV packaging. The module does
not publish packages, download Cisco/Talos installers, or provision private
repositories.

## Metadata and namespace

`metadata.json` now identifies the DanixTech repository and issue tracker while
retaining the existing `edestecd-clamav` module name for compatibility. A Forge
namespace rename must be an explicit publication decision because it changes
the installation coordinate for existing consumers; it is not inferred by
this branch.

Before publication, the maintainer must confirm the desired Forge namespace,
version, release notes, and signing credentials. No Forge upload or signing
operation is performed by CI or by this checklist.

## Publication commands (human review only)

After all gates pass and the namespace/version are approved:

```text
pdk build
puppet module publish pkg/<approved-artifact>.tar.gz
```

The exact artifact name and publication command must be reviewed against the
Forge account and the final metadata. Do not publish a candidate that has not
passed the clean-install check.
