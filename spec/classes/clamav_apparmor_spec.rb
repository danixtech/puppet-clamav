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

  context 'with managed Freshclam validation on Ubuntu' do
    let(:params) { { manage_apparmor: true, manage_freshclam: true } }
    let(:local_profile) { 'clamav apparmor /etc/apparmor.d/local/usr.bin.freshclam' }

    it 'loads the narrow policy before native file validation without dependency cycles' do
      is_expected.to compile.with_all_deps
      is_expected.to contain_file(local_profile).with_content(%r{^"/etc/clamav/freshclam.conf\*" r,$})
                                                .that_requires('Package[freshclam]')
                                                .that_notifies('Exec[clamav-freshclam-apparmor-reload]')
      is_expected.to contain_exec('clamav-freshclam-apparmor-reload').with_refreshonly(true)
                                                                     .that_comes_before('Exec[clamav-freshclam-apparmor-ready]')
      is_expected.to contain_exec('clamav-freshclam-apparmor-ready')
        .with_unless(%r{ check })
        .that_comes_before('File[freshclam.conf]')
      is_expected.to contain_file('freshclam.conf').with_validate_cmd('/usr/bin/env freshclam --config-file % --version')
      is_expected.not_to contain_file('/etc/apparmor.d/usr.bin.freshclam')
    end

    context 'with a custom path containing spaces' do
      let(:params) { super().merge(freshclam_config: '/srv/clamav config/updater.conf') }

      it do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file(local_profile).with_content(%r{^"/srv/clamav config/updater.conf\*" r,$})
      end
    end

    ['*', '?', '[', '{', '"', '\\', "\n", '@'].each do |character|
      context "with unsafe path character #{character.inspect}" do
        let(:params) { super().merge(freshclam_config: "/etc/clamav/#{character}freshclam.conf") }

        it { is_expected.to compile.and_raise_error(%r{freshclam_config}) }
      end
    end

    context 'with caller Freshclam rules' do
      let(:params) do
        super().merge(apparmor_profiles: [{
                        'path' => '/etc/apparmor.d/local/usr.bin.freshclam',
          'content' => '/srv/database/ r,',
          'ensure' => 'present',
                      }])
      end

      it do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file(local_profile).with_content(%r{/srv/database/ r,\n.*\n"/etc/clamav/freshclam.conf\*" r,})
      end
    end

    context 'with a conflicting absent profile' do
      let(:params) do
        super().merge(apparmor_profiles: [{
                        'path' => '/etc/apparmor.d/local/usr.bin.freshclam',
          'content' => '',
          'ensure' => 'absent',
                      }])
      end

      it { is_expected.to compile.and_raise_error(%r{cannot be absent}) }
    end

    context 'without a separate package or service' do
      let(:params) { super().merge(freshclam_package: nil, freshclam_service: nil) }

      it { is_expected.to compile.with_all_deps }
    end

    context 'with an overridden validator' do
      let(:params) { super().merge(freshclam_config_validate_cmd: '/usr/bin/freshclam -c % -V') }

      it { is_expected.to contain_file('freshclam.conf').with_validate_cmd('/usr/bin/freshclam -c % -V') }
    end

    [:manage_freshclam, :validate_configs].each do |setting|
      context "with #{setting} disabled" do
        let(:params) { super().merge(setting => false) }

        it do
          is_expected.to compile.with_all_deps
          is_expected.not_to contain_file(local_profile)
          is_expected.not_to contain_exec('clamav-freshclam-apparmor-reload')
          is_expected.not_to contain_exec('clamav-freshclam-apparmor-ready')
        end
      end
    end
  end

  ['debian-12-x86_64', 'almalinux-9-x86_64'].each do |platform|
    context "with caller profiles on #{platform}" do
      let(:facts) { formally_supported_os_facts.fetch(platform) }
      let(:params) do
        {
          manage_apparmor: true,
          apparmor_profiles: [{ 'path' => '/etc/caller-profile', 'content' => '# caller', 'ensure' => 'present' }],
        }
      end

      it do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file('clamav apparmor /etc/caller-profile').with_content('# caller')
        is_expected.not_to contain_exec('clamav-freshclam-apparmor-reload')
      end
    end
  end
end
