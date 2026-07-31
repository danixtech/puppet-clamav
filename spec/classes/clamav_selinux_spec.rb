require 'spec_helper'

describe 'clamav' do
  let(:facts) { on_supported_os.fetch('almalinux-9-x86_64') }

  it 'does not declare SELinux resources by default' do
    is_expected.to compile.with_all_deps
    is_expected.not_to contain_class('clamav::selinux')
  end

  context 'with SELinux integration disabled and custom paths present' do
    let(:params) do
      {
        managed_directories: [{
          'path' => '/srv/clamav/quarantine',
          'owner' => 'clamav',
          'group' => 'clamav',
          'mode' => '0750',
        }],
        selinux_file_contexts: [{
          'path' => '/srv/clamav/quarantine',
          'type' => 'antivirus_db_t',
          'ensure' => 'present',
        }],
      }
    end

    it { is_expected.not_to contain_class('clamav::selinux') }
    it { is_expected.to contain_file('clamav managed directory /srv/clamav/quarantine') }
  end

  context 'with an invalid SELinux path' do
    let(:params) do
      {
        manage_selinux: true,
        selinux_file_contexts: [{
          'path' => 'relative/path',
          'type' => 'antivirus_db_t',
          'ensure' => 'present',
        }],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{selinux_file_contexts}) }
  end
end
