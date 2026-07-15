require 'spec_helper'

describe 'clamav', type: :class do
  supported_os = on_supported_os

  context 'resolved variable consumption on Debian 11' do
    let(:facts) { supported_os.fetch('debian-11-x86_64') }

    context 'with package defaults' do
      it do
        is_expected.to contain_package('clamav').with(
          name: 'clamav',
          ensure: 'latest',
        )
      end
    end

    context 'with an overridden package and version' do
      let(:params) do
        {
          clamav_package: 'clamav-custom',
          clamav_version: '1.4.3-1',
        }
      end

      it do
        is_expected.to contain_package('clamav').with(
          name: 'clamav-custom',
          ensure: '1.4.3-1',
        )
      end
    end

    context 'with account management and overridden account attributes' do
      let(:params) do
        {
          manage_user: true,
          user: 'clam-scanner',
          group: 'clam-scanner',
          uid: 1234,
          gid: 1235,
          home: '/srv/clamav',
          shell: '/bin/false',
          comment: 'ClamAV scanner',
          groups: ['mail'],
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_group('clamav').with(
          name: 'clam-scanner',
          gid: 1235,
        )
      end

      it do
        is_expected.to contain_user('clamav').with(
          name: 'clam-scanner',
          uid: 1234,
          gid: 1235,
          home: '/srv/clamav',
          shell: '/bin/false',
          comment: 'ClamAV scanner',
          groups: ['mail'],
        )
      end
    end
  end

  context 'resolved variable consumption on RedHat 8 with clamav-milter managed' do
    let(:facts) { supported_os.fetch('redhat-8-x86_64') }
    let(:params) do
      {
        manage_repo: false,
        manage_clamav_milter: true,
        clamav_milter_package: 'clamav-milter-systemd',
        clamav_milter_version: 'latest',
        clamav_milter_config: '/etc/mail/clamav-milter.conf',
        clamav_milter_service: 'clamav-milter',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_package('clamav-milter-systemd').with_ensure('latest')
    end

    it do
      is_expected.to contain_file('/etc/mail/clamav-milter.conf').with(
        owner: 'root',
        group: 'root',
      )
    end
  end
end
