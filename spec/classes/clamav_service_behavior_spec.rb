require 'spec_helper'

supported_os = on_supported_os
ubuntu_2004_facts = supported_os.fetch('ubuntu-20.04-x86_64')
debian_11_facts = supported_os.fetch('debian-11-x86_64')
redhat_8_facts = supported_os.fetch('redhat-8-x86_64')

describe 'clamav', type: :class do
  context 'on Ubuntu 20.04' do
    let(:facts) { ubuntu_2004_facts }
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        clamd_options: { 'FIPSCryptoHashLimits' => false },
        freshclam_options: { 'FIPSCryptoHashLimits' => false },
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_package('clamav-daemon')
        .with_ensure('latest')
        .that_comes_before('File[/etc/clamav/clamd.conf]')
    end

    it { is_expected.not_to contain_service('clamav-daemon.socket') }

    it do
      is_expected.to contain_service('clamav-daemon')
        .with_ensure('running')
        .with_enable(true)
    end

    it do
      is_expected.to contain_file('/etc/clamav/clamd.conf')
        .that_notifies('Service[clamav-daemon]')
        .without_content(%r{^FIPSCryptoHashLimits\s}m)
    end

    it do
      is_expected.to contain_file('/etc/clamav/freshclam.conf')
        .that_notifies('Service[clamav-freshclam]')
        .without_content(%r{^FIPSCryptoHashLimits\s}m)
    end

    it do
      is_expected.to contain_file('/var/run/clamav')
        .with_ensure('directory')
        .with_owner('clamav')
        .with_group('clamav')
        .with_mode('0755')
        .that_comes_before('File[/etc/clamav/freshclam.conf]')
    end
  end

  context 'on Debian 11 with socket activation disabled' do
    let(:facts) { debian_11_facts }
    let(:params) do
      {
        manage_clamd: true,
        clamd_use_socket: false,
        clamd_service_ensure: 'stopped',
        clamd_service_enable: false,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_service('clamav-daemon.socket') }

    it do
      is_expected.to contain_service('clamav-daemon')
        .with_ensure('stopped')
        .with_enable(false)
    end
  end

  context 'on RedHat 8' do
    let(:facts) { redhat_8_facts }
    let(:params) { { manage_clamd: true } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_service('clamav-daemon.socket') }

    it do
      is_expected.to contain_package('clamav-scanner-systemd')
        .with_ensure('latest')
        .that_comes_before('File[/etc/clamd.d/scan.conf]')
    end

    it do
      is_expected.to contain_service('clamd@scan')
        .with_ensure('running')
        .with_enable(true)
        .that_subscribes_to('Package[clamav-scanner-systemd]')
        .that_subscribes_to('File[/etc/clamd.d/scan.conf]')
    end
  end
end
