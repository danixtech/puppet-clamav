# Puppet 8 and OpenVox 8 support strategy

## Recommendation

The module should use one source tree and one Forge artifact for Puppet 8 and
OpenVox 8. The Puppet language, catalog resources, EPP templates, and Hiera data
used by the module do not require runtime-specific implementations.

Formal support should remain evidence based:

- Puppet 8 is catalog tested and runtime tested by the current CI workflows.
- OpenVox 8 is dependency resolved, metadata validated, and catalog tested by
  the OpenVox CI job.
- OpenVox 8 runtime support should not be claimed until Litmus installs an
  OpenVox 8 agent and exercises the supported operating-system matrix.

No separate OpenVox release or module artifact is currently justified. A
separate artifact should be reconsidered only if the runtimes develop
incompatible Puppet language or provider behavior that cannot be isolated
without changing the public interface.

## Dependency and metadata implications

The test bundle selects its implementation with:

```shell
PUPPET_GEM_NAME=openvox PUPPET_GEM_VERSION='~> 8.0' bundle install
```

`openvox` provides the `puppet` Ruby API and executable, so the existing
RSpec-Puppet and Puppet validation tasks run without source changes.

The current development dependency graph is not OpenVox-exclusive. Bolt,
`puppet-syntax`, and `rspec-puppet-facts` declare Ruby dependencies on the
`puppet` gem, so Bundler installs both implementations and warns that both
provide the `puppet` executable. Merely adding `openvox` to the bundle is not
sufficient: without load-path control, the current toolchain can load Puppet's
`puppet.rb` instead. The OpenVox job therefore prepends the selected OpenVox
library directory, asserts the actual loaded file, and reports that source
before running validation and catalogs. A clean local Ruby 3.3 resolution
selected OpenVox 8.23.1 and the complete suite passed with that load-path
control. This proves source/catalog compatibility with the selected OpenVox
implementation, but it is not a pure OpenVox toolchain or agent-runtime test.

Puppet module metadata has a `puppet` requirement but no separate `openvox`
requirement. The `>= 8.0.0 < 9.0.0` declaration records the formally supported
Puppet runtime boundary; it is not, by itself, evidence of OpenVox runtime
support. Do not add an unrecognized metadata requirement.

The `puppet/epel` dependency is a Puppet Forge module dependency, not a Ruby
runtime dependency. Its namespace does not require the proprietary Puppet
runtime. The real EPEL fixture must continue to compile under both runtimes
before EL support is formally shared.

## Required CI evidence

Every supported change should retain:

1. Puppet 8 metadata validation, lint, focused compatibility tests, and the
   complete unit suite.
2. OpenVox 8 dependency resolution, metadata validation, and the complete unit
   suite using the `openvox` gem.
3. Real `puppet/epel` catalog integration under both runtimes.
4. Litmus runtime jobs for each formally supported runtime and operating
   system.

The first two items establish source and catalog compatibility. The latter two
are release gates for formal platform support.

Until upstream test gems accept either implementation without pulling in the
`puppet` gem, package-based Litmus acceptance is the authoritative way to
demonstrate an OpenVox-only runtime.

## Publishing strategy

Publish one module artifact with a single semantic version and identical public
parameters for both runtimes. Release notes and the support matrix must
distinguish:

- source/catalog tested;
- package/runtime tested;
- formally supported.

Forge publication should continue to use valid Puppet metadata. OpenVox support
belongs in the README, release notes, and evidence matrix until the metadata
schema gains a recognized OpenVox requirement.
