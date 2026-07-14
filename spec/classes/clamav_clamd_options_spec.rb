require 'spec_helper'

supported_os = on_supported_os
debian_11_facts = supported_os.fetch('debian-11-x86_64')
ubuntu_2204_facts = supported_os.fetch('ubuntu-22.04-x86_64')

describe 'clamav', type: :class do
  let(:facts) { debian_11_facts }

  context 'with normalized option layers' do
    let(:params) do
      {
        manage_clamd: true,
        clamd_default_options: {
          'MaxThreads' => 20,
          'CallerDefault' => 'present',
        },
        clamd_options: {
          'MaxThreads' => 30,
          'CallerDefault' => :undef,
        },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .with_content(%r{^MaxThreads 30$}m)
        .without_content(%r{^CallerDefault\s}m)
    end

    it 'retains baseline and platform options' do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .with_content(%r{^Bytecode yes$}m)
        .with_content(%r{^LocalSocket /var/run/clamav/clamd\.ctl$}m)
    end
  end

  context 'with explicit undef overrides hash' do
    let(:params) do
      {
        manage_clamd: true,
        clamd_options: :undef,
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .with_content(%r{^Bytecode yes$}m)
    end
  end

  context 'with scalar, repeated, and empty values' do
    let(:params) do
      {
        manage_clamd: true,
        clamd_options: {
          'BooleanOption' => false,
          'EmptyArrayOption' => [],
          'EmptyStringOption' => '',
          'RepeatedOption' => ['first', '', :undef, false, 'second'],
        },
      }
    end

    it do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .with_content(%r{^BooleanOption no$}m)
        .without_content(%r{^EmptyArrayOption\s}m)
        .without_content(%r{^EmptyStringOption\s}m)
        .with_content(%r{^RepeatedOption first\nRepeatedOption no\nRepeatedOption second$}m)
    end
  end

  context 'on Ubuntu 22.04' do
    let(:facts) { ubuntu_2204_facts }
    let(:params) { { manage_clamd: true } }

    it 'uses the canonical platform option data' do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .with_content(%r{^LocalSocket /var/run/clamav/clamd\.ctl$}m)
        .with_content(%r{^PidFile /var/run/clamav/clamd\.pid$}m)
    end
  end
end
