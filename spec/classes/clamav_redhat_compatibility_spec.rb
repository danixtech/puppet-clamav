require 'spec_helper'

supported_os = on_supported_os
redhat_7_facts = supported_os.fetch('redhat-7-x86_64')
redhat_8_facts = supported_os.fetch('redhat-8-x86_64')
redhat_9_facts = Marshal.load(Marshal.dump(redhat_8_facts))
redhat_9_facts[:operatingsystemrelease] = '9.0'
redhat_9_facts[:operatingsystemmajrelease] = '9'
redhat_9_facts[:os]['release']['full'] = '9.0'
redhat_9_facts[:os]['release']['major'] = '9'

describe 'clamav', type: :class do
  let(:pre_condition) { 'class epel {}' }

  {
    'RedHat 7' => redhat_7_facts,
    'RedHat 8' => redhat_8_facts,
    'RedHat 9' => redhat_9_facts,
  }.each do |label, os_facts|
    context "on #{label}" do
      let(:facts) { os_facts }
      let(:params) do
        {
          manage_user: true,
          manage_clamd: true,
          manage_freshclam: true,
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('epel') }

      it do
        is_expected.to contain_package('clamav-scanner-systemd')
          .with_ensure('latest')
      end

      it do
        is_expected.to contain_package('clamav-update')
          .with_ensure('latest')
      end

      it do
        is_expected.to contain_group('clamav').with(
          name: 'clamscan',
          gid: 496,
        )
      end

      it do
        is_expected.to contain_user('clamav').with(
          name: 'clamscan',
          uid: 496,
          gid: 496,
          home: '/',
          shell: '/sbin/nologin',
        )
      end

      it do
        is_expected.to contain_file('/etc/sysconfig/freshclam').with(
          owner: 'root',
          group: 'root',
          mode: '0644',
        )
      end

      it do
        is_expected.to contain_file('/etc/clamd.d/scan.conf')
          .with_content(%r{^LocalSocketGroup clamscan$}m)
          .with_content(%r{^LogSyslog yes$}m)
          .with_content(%r{^TemporaryDirectory /var/tmp$}m)
          .with_content(%r{^User clamscan$}m)
          .without_content(%r{^LogRotate\s}m)
      end

      if label == 'RedHat 9'
        it do
          is_expected.to contain_file('/etc/clamd.d/scan.conf')
            .with_content(%r{^LocalSocket /run/clamd\.scan/clamd\.sock$}m)
            .with_content(%r{^PidFile /run/clamd\.scan/clamd\.pid$}m)
        end
      else
        it do
          is_expected.to contain_file('/etc/clamd.d/scan.conf')
            .with_content(%r{^LocalSocket /var/run/clamd\.scan/clamd\.sock$}m)
            .with_content(%r{^PidFile /var/run/clamd\.scan/clamd\.pid$}m)
            .without_content(%r{^LogFile\s}m)
        end
      end

      if label == 'RedHat 7'
        it { is_expected.not_to contain_service('clamav-freshclam') }
      else
        it do
          is_expected.to contain_service('clamav-freshclam')
            .with_ensure('running')
            .with_enable(true)
        end
      end
    end
  end
end
