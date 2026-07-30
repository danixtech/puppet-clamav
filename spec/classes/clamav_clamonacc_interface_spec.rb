require 'spec_helper'

# rubocop:disable RSpec/MultipleDescribes

debian_12_facts = on_supported_os.fetch('debian-12-x86_64')

describe 'clamav', type: :class do
  let(:facts) { debian_12_facts }

  context 'with default clamonacc policy' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('clamav::clamonacc') }

    it 'does not create clamonacc operational resources' do
      is_expected.not_to contain_package('clamonacc')
      is_expected.not_to contain_file('clamonacc.conf')
      is_expected.not_to contain_service('clamonacc')
    end
  end

  context 'with clamonacc explicitly disabled and legacy options present' do
    let(:params) do
      {
        manage_clamonacc: false,
        clamonacc_options: {
          'ListenMode' => 'LocalSocket',
          'OnAccessIncludePath' => ['/home'],
        },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('clamav::clamonacc') }
  end

  context 'with clamonacc enabled through the legacy options hash' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_options: {
          'ListenMode' => 'LocalSocket',
          'DaemonUsername' => 'clamav',
          'OnAccessIncludePath' => ['/home'],
          'OnAccessExcludePath' => ['/proc', '/sys'],
          'OnAccessExcludeUname' => ['clamav'],
          'TemporaryDirectory' => '/tmp',
        },
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('clamav::clamonacc') }

    it 'creates only the configuration resource at this stage' do
      is_expected.not_to contain_package('clamonacc')
      is_expected.to contain_file('clamonacc.conf')
      is_expected.not_to contain_service('clamonacc')
    end
  end

  context 'with typed operational overrides' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_package: 'clamav-clamonacc',
        clamonacc_package_version: '1.5.3',
        clamonacc_binary: '/opt/clamav/bin/clamonacc',
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_service: 'clamav-onaccess',
        clamonacc_service_ensure: 'stopped',
        clamonacc_service_enable: false,
        clamonacc_listen_mode: 'TCPSocket',
        clamonacc_tcp_port: 3310,
        clamonacc_tcp_address: '127.0.0.1',
        clamonacc_daemon_username: 'scanner',
        clamonacc_include_paths: ['/srv/data'],
        clamonacc_exclude_paths: ['/srv/data/quarantine'],
        clamonacc_exclude_usernames: ['scanner'],
        clamonacc_temporary_directory: '/var/tmp/clamonacc',
        clamonacc_quarantine_path: '/srv/data/quarantine',
        clamonacc_options: {
          'OnAccessIncludePath' => 'relative-legacy-value',
        },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_class('clamav::clamonacc').with(
        package_name: 'clamav-clamonacc',
        package_version: '1.5.3',
        binary_path: '/opt/clamav/bin/clamonacc',
        config_path: '/etc/clamav/clamonacc.conf',
        service_name: 'clamav-onaccess',
        service_ensure: 'stopped',
        service_enable: false,
        listen_mode: 'TCPSocket',
        daemon_username: 'scanner',
        include_paths: ['/srv/data'],
        exclude_paths: ['/srv/data/quarantine'],
        exclude_usernames: ['scanner'],
        temporary_directory: '/var/tmp/clamonacc',
        quarantine_path: '/srv/data/quarantine',
      )
    end
  end

  context 'with clamonacc enabled without an include path' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
      }
    end

    it { is_expected.to compile.and_raise_error(%r{requires at least one include path}) }
  end

  context 'with a relative include path' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_include_paths: ['home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{Stdlib::Absolutepath}) }
  end

  context 'with an invalid listen mode' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_listen_mode: 'socket',
        clamonacc_include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{Clamav::Clamonacc_listen_mode}) }
  end

  context 'with an invalid service ensure value' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_service_ensure: 'latest',
        clamonacc_include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{Clamav::Service_ensure}) }
  end
end

describe 'clamav::clamonacc', type: :class do
  let(:facts) { debian_12_facts }
  let(:params) do
    {
      config_path: '/etc/clamav/clamonacc.conf',
      local_socket: '/run/clamav/clamd.ctl',
      include_paths: ['/home'],
    }
  end

  it { is_expected.to compile.with_all_deps }

  it 'manages only configuration before the later Stage 2 issues' do
    is_expected.not_to contain_package('clamonacc')
    is_expected.to contain_file('clamonacc.conf')
    is_expected.not_to contain_service('clamonacc')
  end
end

# rubocop:enable RSpec/MultipleDescribes
