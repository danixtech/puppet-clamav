require 'spec_helper'

supported_os = on_supported_os

platform_facts = lambda do |base, name, release| # rubocop:disable Style/Lambda
  facts = Marshal.load(Marshal.dump(base))
  major = release.split('.').first
  facts[:operatingsystem] = name
  facts[:operatingsystemrelease] = release
  facts[:operatingsystemmajrelease] = major
  facts[:os]['name'] = name
  facts[:os]['release']['full'] = release
  facts[:os]['release']['major'] = major
  facts
end

ubuntu_22 = supported_os.fetch('ubuntu-22.04-x86_64')
redhat_8 = supported_os.fetch('redhat-8-x86_64')
centos_8 = supported_os.fetch('centos-8-x86_64')

describe 'clamav', type: :class do
  context 'on priority Ubuntu platforms' do
    {
      'Ubuntu 24.04' => platform_facts.call(ubuntu_22, 'Ubuntu', '24.04'),
      'Ubuntu 26.04' => platform_facts.call(ubuntu_22, 'Ubuntu', '26.04'),
    }.each do |label, os_facts|
      context "on #{label}" do
        let(:facts) { os_facts }
        let(:params) { { manage_clamd: true, manage_freshclam: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('clamav-daemon').with_ensure('latest') }
        it { is_expected.to contain_package('clamav-freshclam').with_ensure('latest') }
        it { is_expected.not_to contain_service('clamav-daemon.socket') }

        it do
          is_expected.to contain_service('clamav-daemon')
            .with_ensure('running')
            .with_enable(true)
        end

        it do
          is_expected.to contain_file('/etc/clamav/clamd.conf')
            .with_content(%r{^LocalSocket /var/run/clamav/clamd\.ctl$}m)
            .with_content(%r{^PidFile /var/run/clamav/clamd\.pid$}m)
            .with_content(%r{^User clamav$}m)
        end
      end
    end
  end

  context 'on priority EL and CentOS Stream platforms' do
    {
      'RedHat 10' => platform_facts.call(redhat_8, 'RedHat', '10.0'),
      'CentOS Stream 9' => platform_facts.call(centos_8, 'CentOS', '9'),
      'CentOS Stream 10' => platform_facts.call(centos_8, 'CentOS', '10'),
    }.each do |label, os_facts|
      context "on #{label}" do
        let(:facts) { os_facts }
        let(:pre_condition) { 'class epel {}' }
        let(:params) do
          {
            manage_clamd: true,
            manage_freshclam: true,
            manage_clamav_milter: true,
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('epel') }

        if label.end_with?('10')
          it { is_expected.to contain_package('clamd').with_ensure('latest') }
          it { is_expected.to contain_package('clamav-freshclam').with_ensure('latest') }
          it { is_expected.to contain_package('clamav-milter').with_ensure('latest') }
        else
          it { is_expected.to contain_package('clamav-scanner-systemd').with_ensure('latest') }
          it { is_expected.to contain_package('clamav-update').with_ensure('latest') }
          it { is_expected.to contain_package('clamav-milter-systemd').with_ensure('latest') }
        end

        it do
          is_expected.to contain_service('clamd@scan')
            .with_ensure('running')
            .with_enable(true)
        end

        it do
          is_expected.to contain_file('/etc/clamd.d/scan.conf')
            .with_content(%r{^LocalSocket /run/clamd\.scan/clamd\.sock$}m)
            .with_content(%r{^PidFile /run/clamd\.scan/clamd\.pid$}m)
            .with_content(%r{^User clamscan$}m)
        end
      end
    end
  end
end
