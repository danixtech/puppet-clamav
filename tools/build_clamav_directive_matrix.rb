#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open-uri'
require 'yaml'

VERSIONS = ['1.4.3', '1.5.3'].freeze
COMPONENTS = {
  'clamd' => 'clamd',
  'freshclam' => 'freshclam',
  'milter' => 'clamav-milter',
}.freeze
DATA_KEYS = {
  'clamd' => %r{\Aclamav::(?:clamd_default_options|clamd_platform_options)\z},
  'freshclam' => %r{\Aclamav::(?:freshclam_default_options|freshclam_platform_options)\z},
  'milter' => %r{\Aclamav::milter_default_options\z},
}.freeze

def sample_directives(version, upstream_name)
  url = "https://raw.githubusercontent.com/Cisco-Talos/clamav/clamav-#{version}/etc/#{upstream_name}.conf.sample"
  content = URI.open(url, &:read)
  [url, content.scan(%r{^#?([A-Z][A-Za-z0-9]+)(?:\s|$)}).flatten.uniq.sort]
end

def params_directives
  content = File.read('manifests/params.pp')
  {
    'clamd' => content.match(%r{\$clamd_baseline_options = \{(.*?)^\s+\}}m)[1]
                      .scan(%r{^\s+'([^']+)'\s*=>}).flatten,
    'freshclam' => content.match(%r{\$freshclam_baseline_options = \{(.*?)^\s+\}}m)[1]
                          .scan(%r{^\s+'([^']+)'\s*=>}).flatten,
    'milter' => [],
  }
end

def module_directives
  directives = params_directives
  Dir['data/**/*.yaml'].sort.each do |path|
    data = YAML.safe_load_file(path, aliases: true) || {}
    DATA_KEYS.each do |component, key_pattern|
      data.each do |key, value|
        directives.fetch(component).concat(value.keys.map(&:to_s)) if key.match?(key_pattern) && value.is_a?(Hash)
      end
    end
  end
  directives.transform_values { |values| values.uniq.sort }
end

samples = {}
sources = {}
COMPONENTS.each do |component, upstream_name|
  samples[component] = {}
  VERSIONS.each do |version|
    url, directives = sample_directives(version, upstream_name)
    sources["#{version}-#{component}"] = url
    samples[component][version] = directives
  end
end

matrix = module_directives.to_h do |component, directives|
  evidence = directives.to_h do |directive|
    pre = samples.fetch(component).fetch('1.4.3').include?(directive)
    current = samples.fetch(component).fetch('1.5.3').include?(directive)
    classification = if directive == 'ScanOnAccess'
                       'accepted_but_deprecated_in_1_5'
                     elsif pre && current
                       'supported_pre_1_5_and_1_5'
                     elsif current
                       'introduced_in_1_5'
                     elsif pre
                       'removed_from_1_5_sample'
                     else
                       'not_in_official_samples'
                     end
    [directive, { 'classification' => classification, 'sample_1_4_3' => pre, 'sample_1_5_3' => current }]
  end
  [component, evidence]
end

matrix['clamd']['PreludeAnalyzerName']['classification'] = 'supported_but_inactive_when_prelude_disabled'
matrix['clamd']['BytecodeTimeout']['classification'] = 'native_validated_on_1_5_not_in_samples'
[
  'AlgorithmicDetection',
  'ArchiveBlockEncrypted',
  'OLE2BlockMacros',
  'PartitionIntersection',
  'PhishingAlwaysBlockCloak',
  'PhishingAlwaysBlockSSLMismatch',
].each do |directive|
  matrix['clamd'][directive]['classification'] = 'legacy_release_data_not_emitted_on_ubuntu_1_5'
end
matrix['clamd']['FIPSCryptoHashLimits'] = {
  'classification' => 'available_in_1_5_not_emitted_by_module',
  'sample_1_4_3' => false,
  'sample_1_5_3' => true,
}

output = {
  'schema' => 1,
  'generated_from' => sources,
  'runtime_evidence' => {
    'pre_1_5' => 'Stage 0 package acceptance on supported distribution packages',
    '1_5' => 'Ubuntu 24.04.4, ClamAV 1.5.3, FLEVEL 233, production parity apply and clamconf',
  },
  'directives' => matrix,
}

File.write('docs/clamav-directive-compatibility.yaml', output.to_yaml(line_width: -1))
