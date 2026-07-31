# Systemd hardening evaluation

The module does not currently manage systemd hardening directives. This is an
intentional result of issue #29: supported package units carry
distribution-specific policy, while a generic drop-in can break ClamAV
database updates, Unix sockets, quarantine moves, milter operation, or
fanotify-based on-access scanning.

| Control | Decision | Reason |
| --- | --- | --- |
| `NoNewPrivileges` | Defer | Requires runtime evidence for clamonacc/fanotify and helpers. |
| `ProtectSystem` | Defer | Must allow database, log, runtime, and quarantine paths. |
| `ProtectHome` | Defer | Can prevent scans of caller-selected home paths. |
| `ReadWritePaths` | Defer | Requires a complete inventory across components and custom paths. |
| Capability restrictions | Defer | Fanotify and package capabilities differ by release. |
| Service-specific drop-ins | Do not manage now | Unit names and package ownership differ by distribution. |

No hardening is enabled or altered by the module. Package-native units and
site-managed drop-ins remain authoritative. Callers may manage their own
systemd policy externally, validating with `systemd-analyze security` and
runtime tests.

Before this module offers an optional profile, each control must be validated
independently on maintained Ubuntu, Debian, and Enterprise Linux targets with
clamd startup, freshclam updates, socket access, quarantine, milter, and
clamonacc/fanotify workflows. Custom paths from issue #25 must be included in
`ReadWritePaths` coverage. Unsupported controls must remain disabled rather
than becoming generic exceptions.

This decision keeps the current release compatibility-neutral and leaves any
future hardening interface as a separate evidence-backed change.
