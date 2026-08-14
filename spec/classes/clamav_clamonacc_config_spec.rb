require 'spec_helper'

# rubocop:disable RSpec/MultipleDescribes

debian_12_facts = on_supported_os.fetch('debian-12-x86_64')
ubuntu_2404_facts = formally_supported_os_facts.fetch('ubuntu-24.04-x86_64')
almalinux_9_facts = on_supported_os.fetch('almalinux-9-x86_64')

describe 'clamav', type: :class do
  let(:facts) { debian_12_facts }

  context 'with clamonacc disabled' do
    it { is_expected.not_to contain_file('clamonacc.conf') }
  end

  context 'on Ubuntu 24.04 with the distro-native configuration path omitted' do
    let(:facts) { ubuntu_2404_facts }
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.with_all_deps }

    it 'uses the Debian-family platform default' do
      is_expected.to contain_class('clamav::clamonacc')
        .with_config_path('/etc/clamav/clamonacc.conf')
      is_expected.to contain_file('clamonacc.conf')
        .with_path('/etc/clamav/clamonacc.conf')
    end
  end

  context 'on AlmaLinux 9 with no evidenced configuration path' do
    let(:facts) { almalinux_9_facts }
    let(:params) do
      {
        manage_repo: false,
        manage_clamonacc: true,
        clamonacc_include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{requires config_path}) }
  end

  context 'with local-socket clamonacc configuration' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_listen_mode: 'LocalSocket',
        clamonacc_daemon_username: 'clamav',
        clamonacc_include_paths: ['/home', '/srv/data'],
        clamonacc_exclude_paths: ['/home/quarantine', '/proc'],
        clamonacc_exclude_usernames: ['clamav', 'root'],
        clamonacc_temporary_directory: '/var/tmp/clamonacc',
        clamonacc_options: {
          'OnAccessMaxFileSize' => '25M',
          'OnAccessPrevention' => true,
          'EmptyOption' => '',
          'UnsetOption' => :undef,
          'ListenMode' => 'TCPSocket',
          'DaemonUsername' => 'legacy-user',
          'LocalSocket' => '/legacy/clamd.sock',
          'OnAccessIncludePath' => ['/legacy'],
          'OnAccessExcludeUname' => ['legacy-user'],
        },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_file('clamonacc.conf').with(
        ensure: 'file',
        path: '/etc/clamav/clamonacc.conf',
        owner: 'root',
        group: 'root',
        mode: '0644',
        validate_cmd: '/usr/bin/env clamonacc --config-file % --help',
      )
    end

    it 'does not use the nonzero --version command as the default validator' do
      validator = catalogue.resource('File[clamonacc.conf]')[:validate_cmd]

      expect(validator).to include('--help')
      expect(validator).not_to include('--version')
    end

    it 'renders native deterministic directives with typed values taking precedence' do
      expected = <<~CONFIG
        ### File managed with puppet ###
        ## Module:           'clamav'

        LocalSocket /var/run/clamav/clamd.ctl
        User clamav
        TemporaryDirectory /var/tmp/clamonacc
        OnAccessIncludePath /home
        OnAccessIncludePath /srv/data
        OnAccessExcludePath /home/quarantine
        OnAccessExcludePath /proc
        OnAccessExcludeUname clamav
        OnAccessExcludeUname root
        OnAccessMaxFileSize 25M
        OnAccessPrevention true
      CONFIG

      is_expected.to contain_file('clamonacc.conf').with_content(expected)
    end

    it 'does not render pseudo, conflicting, empty, or unset directives' do
      is_expected.to contain_file('clamonacc.conf')
        .without_content(%r{^ListenMode\s}m)
        .without_content(%r{^DaemonUsername\s}m)
        .without_content(%r{^TCPSocket\s}m)
        .without_content(%r{^TCPAddr\s}m)
        .without_content(%r{legacy})
        .without_content(%r{^EmptyOption\s}m)
        .without_content(%r{^UnsetOption\s}m)
    end
  end

  context 'with TCP clamonacc configuration' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_listen_mode: 'TCPSocket',
        clamonacc_tcp_port: 3310,
        clamonacc_tcp_address: '127.0.0.1',
        clamonacc_include_paths: ['/srv/data'],
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_file('clamonacc.conf')
        .with_content(%r{^TCPSocket 3310$}m)
        .with_content(%r{^TCPAddr 127\.0\.0\.1$}m)
        .without_content(%r{^LocalSocket\s}m)
    end
  end

  context 'with a custom validation command and file policy' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/opt/clamav/etc/clamonacc.conf',
        clamonacc_config_owner: 'scanner',
        clamonacc_config_group: 'scanner',
        clamonacc_config_mode: '0440',
        clamonacc_config_validate_cmd: '/opt/clamav/sbin/clamonacc --config-file=% --version',
        clamonacc_local_socket: '/opt/clamav/run/clamd.sock',
        clamonacc_include_paths: ['/srv/data'],
      }
    end

    it do
      is_expected.to contain_file('clamonacc.conf').with(
        path: '/opt/clamav/etc/clamonacc.conf',
        owner: 'scanner',
        group: 'scanner',
        mode: '0440',
        validate_cmd: '/opt/clamav/sbin/clamonacc --config-file=% --version',
      )
    end
  end

  context 'with validation disabled globally' do
    let(:params) do
      {
        manage_clamonacc: true,
        validate_configs: false,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_include_paths: ['/home'],
      }
    end

    it { is_expected.to contain_file('clamonacc.conf').with_validate_cmd(nil) }
  end
end

describe 'clamav::clamonacc', type: :class do
  let(:facts) { debian_12_facts }

  context 'with a directly declared local-socket configuration' do
    let(:params) do
      {
        config_path: '/etc/clamav/clamonacc.conf',
        local_socket: '/run/clamav/clamd.ctl',
        include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_file('clamonacc.conf').with_content(%r{^LocalSocket /run/clamav/clamd\.ctl$}m) }
    it { is_expected.not_to contain_package('clamonacc') }
    it { is_expected.not_to contain_service('clamonacc') }
  end

  context 'without a configuration path' do
    let(:params) do
      {
        local_socket: '/run/clamav/clamd.ctl',
        include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{requires config_path}) }
  end

  context 'with local-socket mode and no socket path' do
    let(:params) do
      {
        config_path: '/etc/clamav/clamonacc.conf',
        listen_mode: 'LocalSocket',
        include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{LocalSocket mode requires local_socket}) }
  end

  context 'with TCP mode and no port' do
    let(:params) do
      {
        config_path: '/etc/clamav/clamonacc.conf',
        listen_mode: 'TCPSocket',
        tcp_address: '127.0.0.1',
        include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{TCPSocket mode requires tcp_port}) }
  end

  context 'with TCP mode and no address' do
    let(:params) do
      {
        config_path: '/etc/clamav/clamonacc.conf',
        listen_mode: 'TCPSocket',
        tcp_port: 3310,
        include_paths: ['/home'],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{TCPSocket mode requires tcp_address}) }
  end
end

# rubocop:enable RSpec/MultipleDescribes
