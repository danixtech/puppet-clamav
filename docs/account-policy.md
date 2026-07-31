# ClamAV account-management policy

Issue #22 establishes the migration design without changing the existing
account defaults or taking ownership of package-created accounts.

## Existing behavior retained

`manage_user => false` remains a complete suppression switch. When account
management is enabled, the module retains the established platform defaults,
including numeric UID/GID 496, and manages the scanner account and group using
the caller-provided names. Existing package-created accounts therefore remain
the caller's responsibility when management is disabled.

The current compatibility edge case is intentional: disabling group management
does not suppress the user resource, and the user can still receive the
configured numeric `gid`. This behavior is characterized by the unit suite and
is not changed by this issue.

## Future typed policy

Future account work should expose an explicit, constrained policy with these
modes:

* `package` — use distro/package-created accounts and do not manage them;
* `managed` — manage named accounts, with UID/GID values validated together;
* `unmanaged` — suppress account resources while allowing callers to provide
  names to component services.

The transition must preserve the current false-suppression behavior and provide
an explicit migration path before changing numeric defaults. A managed user
must not silently reference a group that the module is forbidden to manage,
unless the caller explicitly selects a package/external-group contract.

## Collision and migration requirements

Before implementation changes, acceptance evidence must characterize distro
accounts and ownership on Ubuntu, Debian, and Enterprise Linux. The eventual
implementation must cover UID/GID collisions, package-created users, direct
child-class declarations, user-without-group combinations, and ownership
resources. No default UID/GID or package-owned account will change implicitly.
