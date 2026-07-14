# Repository Guidelines

## Project Structure & Module Organization

This Puppet module manages ClamAV. Classes live in `manifests/`; `init.pp` is the main `clamav` class, while `clamd.pp`, `freshclam.pp`, and `clamav_milter.pp` manage components. Module Hiera 5 defaults are under `data/`, selected by `hiera.yaml`. Templates are in `templates/`.

Unit tests are in `spec/classes/`. Acceptance tests and legacy Vagrant nodesets are under `spec/acceptance/`. Compatibility and dependencies are declared in `metadata.json`; development tooling is defined by `Gemfile` and `Rakefile`.

## Build, Test, and Development Commands

Use the repository's Bundler environment. Coordinate dependency changes separately.

- `bundle exec rake validate`: run metadata, syntax, and lint validation provided by the Puppet tooling.
- `bundle exec rake spec`: run the rspec-puppet unit suite.
- `bundle exec rake`: run the default validation and test tasks.
- `bundle exec puppet parser validate manifests/*.pp`: perform a focused manifest syntax check.
- `bundle exec puppet-lint manifests`: lint Puppet code.
- `bundle exec rake litmus:list`: inspect Litmus targets. Existing Beaker nodesets are historical, not the current support matrix.

## Coding Style & Naming Conventions

Use two-space indentation in Puppet, Ruby, YAML, and EPP files. Follow Puppet class naming (`clamav`, `clamav::clamd`) and snake_case parameters. Keep OS data keys aligned with public parameters, for example `clamav::clamd_default_options`. Prefer typed parameters, EPP templates, structured facts (`$facts['os']`), and explicit class relationships. Run Puppet Lint and RuboCop before submitting Ruby or manifest changes.

## Testing Guidelines

Write rspec-puppet examples in files ending `_spec.rb`. Cover each affected OS family, parameter precedence, generated configuration, package/service relationships, and idempotency. Treat socket activation, ownership, and option merging as compatibility-critical. There is no meaningful minimum coverage threshold, but new behavior requires regression tests.

## Commit & Pull Request Guidelines

History uses short, imperative or explanatory commit subjects such as `fixing the database owner problem`. Prefer a concise imperative subject that names the affected behavior, and keep unrelated cleanup separate.

Pull requests should explain the motivation, affected OS and ClamAV versions, compatibility impact, tests run, and configuration or service changes. Link relevant issues. Include before/after catalog or config excerpts when defaults, packages, users, sockets, or services change; screenshots are unnecessary.

## Compatibility and Configuration Safety

Do not silently rename Hiera keys or change default option hashes. Such changes can rewrite complete ClamAV configuration files and restart services. Preserve existing user overrides, document migrations, and test both Debian-family socket activation and RedHat-family service activation.
