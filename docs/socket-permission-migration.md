# ClamAV socket-permission migration

The module currently renders `LocalSocketMode 666` by default. This is a
deliberate compatibility setting: any local account that can reach the socket
can connect to clamd. A future release may make `660` the default, but that is
a breaking change and is not enabled by this design issue.

## Migration boundary

The default must remain `666` through the current compatibility release. A
future major or otherwise explicitly announced breaking release may change the
default to `660`, after the deprecation period below and after the supported
platform matrix has been tested. The change must be called out in release
notes and a migration guide; it must not be hidden in a data refresh.

## Site migration steps

Before selecting `660`, an operator should:

1. Inventory local clients that connect to the clamd socket, including
   clamonacc, milter, monitoring, backup, and site-specific scanner accounts.
2. Set `LocalSocketGroup` to a dedicated group where the platform package
   supports it, and add every required client account to that group.
3. Set the public `clamd_options['LocalSocketMode']` override to `660`.
4. Apply the change during a maintenance window and verify authorized clients
   can scan while an unrelated local account is denied access.
5. Keep a rollback override of `666` until the client inventory is proven
   complete.

The module does not create groups, infer client accounts, or change ownership
of package-managed socket parents as part of this migration. Account and
directory ownership remain explicit caller or package policy.

## Required evidence before changing the default

The implementation change must include runtime tests on maintained Debian,
Ubuntu, and Enterprise Linux targets covering:

- default mode and explicit `660` override;
- socket ownership and `LocalSocketGroup` behavior;
- successful access by an authorized client;
- denied access by an unauthorized client;
- direct-service and socket-activation paths;
- two-run idempotency and upgrade/rollback behavior.

The existing unit characterization tests remain in force and must continue to
prove that the default is `666` and that callers can explicitly select `660`.

## Scope boundary

This document defines the migration only. It does not change the default,
implement SELinux/AppArmor policy, redesign account management, or alter
socket activation. Those concerns require separate evidence and review.
