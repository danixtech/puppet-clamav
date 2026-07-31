require 'spec_helper'

describe 'clamav' do
  let(:facts) { formally_supported_os_facts.fetch('ubuntu-24.04-x86_64') }

  it 'does not declare AppArmor resources by default' do
    is_expected.to compile.with_all_deps
    is_expected.not_to contain_class('clamav::apparmor')
  end

  context 'with AppArmor disabled and a caller profile supplied' do
    let(:params) do
      {
        apparmor_profiles: [{
          'path' => '/etc/apparmor.d/local/usr.sbin.clamd',
          'content' => "# custom ClamAV paths\n",
          'ensure' => 'present',
        }],
      }
    end

    it { is_expected.not_to contain_class('clamav::apparmor') }
  end

  context 'with an invalid AppArmor profile path' do
    let(:params) do
      {
        manage_apparmor: true,
        apparmor_profiles: [{
          'path' => 'relative/profile',
          'content' => 'profile clamd { }',
          'ensure' => 'present',
        }],
      }
    end

    it { is_expected.to compile.and_raise_error(%r{apparmor_profiles}) }
  end
end
