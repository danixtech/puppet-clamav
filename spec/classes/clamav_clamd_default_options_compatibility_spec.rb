require 'spec_helper'

describe 'clamav', type: :class do
  let(:facts) { on_supported_os.fetch('debian-11-x86_64') }

  context 'when clamd_default_options is supplied' do
    let(:params) do
      {
        manage_clamd: true,
        clamd_default_options: {
          'MaxThreads' => 20,
          'ReplacementDefault' => 'present',
        },
        clamd_options: {
          'MaxThreads' => 30,
          'CallerOption' => 'present',
        },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it 'replaces the module and platform defaults as on master' do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .without_content(%r{^Bytecode\s}m)
        .without_content(%r{^LocalSocket\s}m)
        .without_content(%r{^PidFile\s}m)
    end

    it 'still applies clamd_options over the replacement defaults' do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .with_content(%r{^MaxThreads 30$}m)
        .with_content(%r{^ReplacementDefault present$}m)
        .with_content(%r{^CallerOption present$}m)
    end
  end
end
