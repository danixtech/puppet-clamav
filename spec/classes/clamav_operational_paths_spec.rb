require 'spec_helper'

describe 'clamav' do
  let(:facts) { formally_supported_os_facts.fetch('debian-12-x86_64') }

  it 'does not manage log files by default' do
    is_expected.to compile.with_all_deps
    is_expected.not_to contain_file('clamav managed log /var/log/clamav/clamd.log')
  end

  context 'with an explicitly managed log file' do
    let(:params) do
      {
        managed_log_files: [{
          'path' => '/srv/clamav/logs/clamd.log',
          'owner' => 'clamav',
          'group' => 'clamav',
          'mode' => '0640',
        }],
      }
    end

    it do
      is_expected.to contain_file('clamav managed log /srv/clamav/logs/clamd.log').with(
        ensure: 'file',
        owner: 'clamav',
        group: 'clamav',
        mode: '0640',
      )
    end
  end

  context 'with an unsafe log path' do
    let(:params) { { managed_log_files: [{ 'path' => 'relative/clamd.log' }] } }

    it { is_expected.to compile.and_raise_error(%r{managed_log_files}) }
  end
end
