require 'spec_helper'

supported_os = on_supported_os

describe 'clamav', type: :class do
  [
    'debian-8-x86_64',
    'debian-9-x86_64',
    'debian-11-x86_64',
    'ubuntu-14.04-x86_64',
    'ubuntu-16.04-x86_64',
    'ubuntu-18.04-x86_64',
    'ubuntu-20.04-x86_64',
    'ubuntu-22.04-x86_64',
  ].each do |os|
    context "on #{os}" do
      let(:facts) { supported_os.fetch(os) }
      let(:params) do
        {
          manage_user: true,
          manage_clamd: true,
          manage_freshclam: true,
        }
      end

      it { is_expected.to compile.with_all_deps }

      it do
        is_expected.to contain_user('clamav').with(
          name: 'clamav',
          uid: 496,
          gid: 496,
          home: '/var/lib/clamav',
          shell: '/bin/false',
        )
      end

      it do
        is_expected.to contain_file('/etc/clamav/clamd.conf')
          .with_content(%r{^LocalSocket /var/run/clamav/clamd\.ctl$}m)
          .with_content(%r{^LocalSocketGroup clamav$}m)
          .with_content(%r{^PidFile /var/run/clamav/clamd\.pid$}m)
          .with_content(%r{^LogFile /var/log/clamav/clamav\.log$}m)
          .with_content(%r{^TemporaryDirectory /tmp$}m)
          .with_content(%r{^User clamav$}m)
      end

      it do
        is_expected.to contain_file('/etc/clamav/freshclam.conf')
          .with_content(%r{^DatabaseOwner clamav$}m)
          .with_content(%r{^PidFile /var/run/clamav/freshclam\.pid$}m)
          .with_content(%r{^UpdateLogFile /var/log/clamav/freshclam\.log$}m)
      end

      it { is_expected.not_to contain_file('/etc/default/freshclam') }

      context 'service activation policy' do
        it { is_expected.not_to contain_service('clamav-daemon.socket') }

        it do
          is_expected.to contain_service('clamav-daemon')
            .with_ensure('running')
            .with_enable(true)
        end
      end

      if os == 'ubuntu-20.04-x86_64'
        it do
          is_expected.to contain_file('/var/run/clamav')
            .with_ensure('directory')
            .with_owner('clamav')
            .with_group('clamav')
            .with_mode('0755')
        end
      end
    end
  end
end
