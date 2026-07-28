# frozen_string_literal: true

RSpec.configure do |c|
  c.mock_with :rspec
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))

include RspecPuppetFacts

default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}

default_fact_files = [
  File.expand_path(File.join(File.dirname(__FILE__), 'default_facts.yml')),
  File.expand_path(File.join(File.dirname(__FILE__), 'default_module_facts.yml')),
]

default_fact_files.each do |f|
  next unless File.exist?(f) && File.readable?(f) && File.size?(f)

  begin
    default_facts.merge!(YAML.safe_load(File.read(f), permitted_classes: [], permitted_symbols: [], aliases: true))
  rescue StandardError => e
    RSpec.configuration.reporter.message "WARNING: Unable to load #{f}: #{e}"
  end
end

# read default_facts and merge them over what is provided by facterdb
default_facts.each do |fact, value|
  add_custom_fact fact, value
end

RSpec.configure do |c|
  c.default_facts = default_facts
  c.before :each do
    # set to strictest setting for testing
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = :warning
    Puppet.settings[:strict_variables] = true
  end
  c.filter_run_excluding(bolt: true) unless ENV['GEM_BOLT']
  c.after(:suite) do
    RSpec::Puppet::Coverage.report!(0)
  end

  # Filter backtrace noise
  backtrace_exclusion_patterns = [
    %r{spec_helper},
    %r{gems},
  ]

  if c.respond_to?(:backtrace_exclusion_patterns)
    c.backtrace_exclusion_patterns = backtrace_exclusion_patterns
  elsif c.respond_to?(:backtrace_clean_patterns)
    c.backtrace_clean_patterns = backtrace_exclusion_patterns
  end
end

# Ensures that a module is defined
# @param module_name Name of the module
def ensure_module_defined(module_name)
  module_name.split('::').reduce(Object) do |last_module, next_module|
    last_module.const_set(next_module, Module.new) unless last_module.const_defined?(next_module, false)
    last_module.const_get(next_module, false)
  end
end

# Compatibility examples intentionally exercise legacy platforms that are no
# longer formal metadata support claims. Keep those fixtures explicit so
# narrowing the maintained support matrix does not erase public-behavior
# characterization.
def characterized_os_facts
  on_supported_os(
    supported_os: [
      {
        'operatingsystem' => 'Debian',
        'operatingsystemrelease' => ['11'],
      },
      {
        'operatingsystem' => 'RedHat',
        'operatingsystemrelease' => ['7', '8'],
      },
      {
        'operatingsystem' => 'Ubuntu',
        'operatingsystemrelease' => ['20.04', '22.04'],
      },
    ],
  )
end

# FacterDB 1.26.0 does not contain Ubuntu 24.04, but it remains pinned for
# parser compatibility with historical facts. Derive only that missing fact
# set from Ubuntu 22.04 and fail if any other formal metadata row disappears
# from the catalog matrix.
def formally_supported_os_facts
  expected = RspecPuppetFacts.meta_supported_os.flat_map do |os|
    os.fetch('operatingsystemrelease').map do |release|
      "#{os.fetch('operatingsystem').downcase}-#{release}-x86_64"
    end
  end
  facts = on_supported_os

  if expected.include?('ubuntu-24.04-x86_64') && !facts.key?('ubuntu-24.04-x86_64')
    ubuntu_facts = Marshal.load(Marshal.dump(characterized_os_facts.fetch('ubuntu-22.04-x86_64')))
    ubuntu_facts[:operatingsystemrelease] = '24.04'
    ubuntu_facts[:operatingsystemmajrelease] = '24.04'
    ubuntu_facts[:os]['release']['full'] = '24.04'
    ubuntu_facts[:os]['release']['major'] = '24.04'
    facts['ubuntu-24.04-x86_64'] = ubuntu_facts
  end

  missing = expected - facts.keys
  raise "No catalog facts available for formal support rows: #{missing.join(', ')}" unless missing.empty?

  facts
end

# 'spec_overrides' from sync.yml will appear below this line
