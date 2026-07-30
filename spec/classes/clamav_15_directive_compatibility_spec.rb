require 'spec_helper'
require 'yaml'

describe 'ClamAV directive compatibility evidence' do
  let(:matrix) { YAML.safe_load_file('docs/clamav-directive-compatibility.yaml') }

  def data_directives
    patterns = {
      'clamd' => %r{\Aclamav::(?:clamd_default_options|clamd_platform_options)\z},
      'freshclam' => %r{\Aclamav::(?:freshclam_default_options|freshclam_platform_options)\z},
      'milter' => %r{\Aclamav::milter_default_options\z},
    }
    patterns.to_h do |component, pattern|
      values = Dir['data/**/*.yaml'].flat_map do |path|
        data = YAML.safe_load_file(path, aliases: true) || {}
        data.filter_map { |key, options| options.keys.map(&:to_s) if key.match?(pattern) && options.is_a?(Hash) }
      end
      [component, values.flatten.uniq]
    end
  end

  it 'records both pre-1.5 and 1.5 upstream sources' do
    expect(matrix.fetch('generated_from').keys).to contain_exactly(
      '1.4.3-clamd', '1.4.3-freshclam', '1.4.3-milter',
      '1.5.3-clamd', '1.5.3-freshclam', '1.5.3-milter'
    )
  end

  it 'records native runtime evidence for both compatibility generations' do
    expect(matrix.fetch('runtime_evidence').keys).to contain_exactly('pre_1_5', '1_5')
  end

  it 'classifies every matrix entry' do
    matrix.fetch('directives').each_value do |directives|
      directives.each_value do |evidence|
        expect(evidence.fetch('classification')).not_to be_empty
        expect(evidence.fetch('sample_1_4_3')).to be(true).or be(false)
        expect(evidence.fetch('sample_1_5_3')).to be(true).or be(false)
      end
    end
  end

  it 'classifies every directive supplied by module data' do
    data_directives.each do |component, directives|
      expect(matrix.fetch('directives').fetch(component).keys).to include(*directives)
    end
  end

  it 'characterizes the known ClamAV 1.5 edge cases' do
    clamd = matrix.fetch('directives').fetch('clamd')
    expect(clamd.fetch('ScanOnAccess').fetch('classification')).to eq('accepted_but_deprecated_in_1_5')
    expect(clamd.fetch('PreludeAnalyzerName').fetch('classification'))
      .to eq('supported_but_inactive_when_prelude_disabled')
    expect(clamd.fetch('FIPSCryptoHashLimits').fetch('classification'))
      .to eq('available_in_1_5_not_emitted_by_module')
  end
end
