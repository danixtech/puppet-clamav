# Template policy

Issue #24 records the template compatibility decision without changing
generated configuration semantics.

## Active rendering path

Managed resources use the EPP templates under `templates/`. Their behavior is
characterized by the unit suite for scalar, Boolean, repeated, empty, and
sorted/unsorted values. EPP emits Puppet-compatible Boolean text (`true` or
`false`) and deterministic repeated directives; empty and undef values remain
omitted.

The module does not convert Boolean values to `yes`/`no` globally. Directive
syntax remains subject to the supported ClamAV parser and version-specific
evidence.

## ERB compatibility decision

The legacy ERB files remain in the module for one compatibility cycle because
external consumers may call `template()` directly. They are not used by the
module's managed resources. Their retained status is deliberate, not an
indication that new resources should use ERB.

Removal requires an explicit deprecation notice, release notes, and evidence
that direct template consumers have a migration path to EPP or a supported
resource interface. No ERB file is removed in this change.

## Validation boundary

Native configuration validation remains the authoritative check for supported
ClamAV versions. Template tests prove rendering semantics; acceptance tests
prove that generated configurations parse and services operate on the tested
package versions.
