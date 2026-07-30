# ClamAV 1.5 directive compatibility

Issue #9 characterizes the directives emitted by this module without changing
their defaults. The machine-readable matrix is
`docs/clamav-directive-compatibility.yaml`.

The matrix compares module-provided clamd, freshclam, and milter directives
with the official ClamAV 1.4.3 and 1.5.3 sample configurations. It is generated
by:

```shell
ruby tools/build_clamav_directive_matrix.rb
```

The checked-in snapshot makes the classification test deterministic and keeps
normal test runs offline. Regeneration requires network access and should be
reviewed as an evidence update.

## Runtime evidence

- Pre-1.5 behavior is covered by the Stage 0 acceptance targets using their
  distribution ClamAV packages.
- ClamAV 1.5 behavior was validated on Ubuntu 24.04.4 with ClamAV 1.5.3,
  functionality level 233. The generated clamd and freshclam configurations
  parsed successfully and both services remained healthy.
- Boolean, repeated/array, and empty-value rendering remains characterized by
  the EPP rendering specs.

## Decisions

- `ScanOnAccess` is still accepted by ClamAV 1.5.3 but emits a deprecation
  warning. Removal is a follow-up compatibility change, not part of this
  characterization.
- `FIPSCryptoHashLimits` is available in ClamAV 1.5, is not a module default,
  and remains available through the clamd and freshclam caller option hashes.
  The [FIPS characterization](clamav-1.5-fips.md) records the runtime evidence
  and explains why no global default is safe.
- `PreludeAnalyzerName` is supported but operationally inactive while Prelude
  is disabled.
- Directives absent from an upstream sample are not automatically considered
  invalid. Native validation is authoritative; sample absence identifies
  follow-up investigation rather than authorizing removal.

## Follow-up gates

- Issue #10 should use native configuration preflight before service refresh.
- Issues #11 and #12 should capture exact native validation on Debian-family
  and Enterprise Linux ClamAV 1.5 packages.
- A formal FIPS-enabled support claim remains gated on a reproducible target
  that records authoritative enabled state and passes update, service, scan,
  and convergence checks.
- Any removal or version gate must receive a separate compatibility test and
  migration note.
