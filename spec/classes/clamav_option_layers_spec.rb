require 'spec_helper'

supported_os = characterized_os_facts
ubuntu_2004_facts = supported_os.fetch('ubuntu-20.04-x86_64')
redhat_8_facts = supported_os.fetch('redhat-8-x86_64')

describe 'clamav', type: :class do
  context 'on Ubuntu 20.04 without release-specific data' do
    let(:facts) { ubuntu_2004_facts }
    let(:params) { { manage_clamd: true, manage_freshclam: true } }

    it { is_expected.to compile.with_all_deps }

    it 'combines generic clamd defaults with Debian platform data' do
      is_expected.to contain_file('clamd.conf')
        .with_content(%r{^Bytecode true$}m)
        .with_content(%r{^LocalSocket /var/run/clamav/clamd\.ctl$}m)
        .with_content(%r{^LocalSocketGroup clamav$}m)
        .with_content(%r{^LogFile /var/log/clamav/clamav\.log$}m)
        .with_content(%r{^PidFile /var/run/clamav/clamd\.pid$}m)
        .with_content(%r{^TemporaryDirectory /tmp$}m)
        .with_content(%r{^User clamav$}m)
    end

    it 'combines generic freshclam defaults with Debian platform data' do
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^Bytecode true$}m)
        .with_content(%r{^DatabaseOwner clamav$}m)
        .with_content(%r{^PidFile /var/run/clamav/freshclam\.pid$}m)
        .with_content(%r{^UpdateLogFile /var/log/clamav/freshclam\.log$}m)
    end
  end

  context 'on RedHat 8 without release-specific data' do
    let(:facts) { redhat_8_facts }
    let(:params) do
      {
        manage_repo: false,
        manage_clamd: true,
        manage_freshclam: true,
      }
    end

    it { is_expected.to compile.with_all_deps }

    it 'combines generic clamd defaults with RedHat platform data' do
      is_expected.to contain_file('clamd.conf')
        .with_content(%r{^Bytecode true$}m)
        .with_content(%r{^LocalSocket /var/run/clamd\.scan/clamd\.sock$}m)
        .with_content(%r{^LocalSocketGroup clamscan$}m)
        .with_content(%r{^LogSyslog true$}m)
        .with_content(%r{^PidFile /var/run/clamd\.scan/clamd\.pid$}m)
        .with_content(%r{^TemporaryDirectory /var/tmp$}m)
        .with_content(%r{^User clamscan$}m)
        .without_content(%r{^LogFile\s}m)
        .without_content(%r{^LogRotate\s}m)
    end

    it 'combines generic freshclam defaults with RedHat platform data' do
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^DatabaseOwner clamupdate$}m)
        .with_content(%r{^LogSyslog true$}m)
        .without_content(%r{^PidFile\s}m)
        .without_content(%r{^UpdateLogFile\s}m)
    end
  end
end
