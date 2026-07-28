# Development and CI

GitHub Actions is the authoritative CI service for this repository. The
development bundle and both workflows use Ruby 3.3. The Gemfile permits Ruby
3.2 through 3.x so contributors receive a clear dependency error rather than
falling through legacy Ruby-specific pins.

## Install and select a runtime

Install the locked bundle for Puppet 8:

```shell
PUPPET_GEM_VERSION='~> 8.0' bundle install
```

The default runtime gem is `puppet`. To exercise OpenVox instead:

```shell
PUPPET_GEM_NAME=openvox bundle install
```

The lock file records both runtimes. OpenVox requires its library directory at
the front of `RUBYLIB` when running shared Puppet tooling; the CI workflow is
the executable reference for that invocation.

## Dependency policy

Development dependencies are direct only when a repository task or supported
developer workflow uses them. Notable deliberate pins are:

* `facterdb` 1.26.0 and JSON 2.9.x form the tested fact database/parser pair.
  Historical Windows facts in facterdb 1.x contain paths rejected by later
  JSON parsers, so changing either constraint requires running the explicit
  database parse check and the complete catalog suite.
* `parallel_tests` remains direct because Litmus supplies
  `litmus:acceptance:parallel` as the documented acceptance entry point.
* RuboCop and its plugins remain mutually pinned. Upgrade them together in a
  focused style-tooling change rather than mixing new lint rules with module
  behavior.

The repository does not upload coverage to Codecov and has no dependency-check
or interactive-debugger task. Those former PDK-era gems are intentionally not
part of the reproducible bundle.

## Local checks

Prepare fixtures before running focused examples directly:

```shell
bundle exec rake spec_prep
```

Run the same static and catalog checks used by the main workflow:

```shell
bundle exec rake validate
bundle exec rake rubocop
bundle exec rspec \
  spec/classes/clamav_compatibility_characterization_spec.rb \
  spec/classes/clamav_epp_rendering_spec.rb \
  spec/classes/clamav_freshclam_runtime_spec.rb \
  spec/classes/clamav_option_layers_spec.rb \
  spec/classes/clamav_socket_activation_spec.rb
bundle exec rake spec
bundle exec rspec spec/classes/clamav_epel_integration_spec.rb
```

The main CI workflow also runs the complete suite with OpenVox selected.

## Evidence boundaries

The main CI workflow validates syntax, style, catalog behavior, the selected
Puppet/OpenVox runtime, and legacy EPEL resource integration. The
runtime-acceptance workflow provisions containers and validates packages,
native configuration parsing, services, database updates, socket activation,
permissions, and two-run convergence.

Catalog success is not runtime evidence. A platform or ClamAV version becomes
a formal support claim only when its required runtime evidence is present and
the support metadata and documentation are updated deliberately.
