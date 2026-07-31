require 'spec_helper'

describe 'clamav' do
  let(:facts) { formally_supported_os_facts.fetch('ubuntu-24.04-x86_64') }

  it 'does not create scheduled scans by default' do
    is_expected.to compile.with_all_deps
    is_expected.not_to contain_file('clamav-scan-daily.service')
    is_expected.not_to contain_service('clamav-scan-daily')
  end

  context 'with an opt-in scheduled scan' do
    let(:params) do
      {
        scheduled_scans: [{
          'name' => 'daily',
          'schedule' => '*-*-* 02:00:00',
          'paths' => ['/home', '/srv/data'],
          'excludes' => ['/home/cache'],
          'scanner' => 'clamscan',
          'user' => 'clamav',
          'log' => '/var/log/clamav/daily.log',
          'quarantine_path' => '/srv/quarantine',
        }],
      }
    end

    it do
      is_expected.to contain_file('clamav-scan-daily.service').with_content(
        %r{ExecStart=/usr/bin/clamscan --recursive --exclude=/home/cache --log=/var/log/clamav/daily\.log --move=/srv/quarantine /home /srv/data},
      )
    end
    it { is_expected.to contain_file('clamav-scan-daily.timer').with_content(%r{OnCalendar=\*-\*-\* 02:00:00}) }
    it { is_expected.to contain_service('clamav-scan-daily').with(name: 'clamav-scan-daily.timer', enable: true) }
  end

  context 'with an unsafe path' do
    let(:params) do
      { scheduled_scans: [{ 'name' => 'daily', 'schedule' => 'daily', 'paths' => ['relative/path'], 'scanner' => 'clamscan', 'user' => 'root' }] }
    end

    it { is_expected.to compile.and_raise_error(%r{scheduled_scans}) }
  end
end
