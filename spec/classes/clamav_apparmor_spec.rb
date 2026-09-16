# frozen_string_literal: true

require 'spec_helper'

describe 'clamav' do
  let(:facts) { formally_supported_os_facts.fetch('ubuntu-24.04-x86_64') }

  it 'does not manage AppArmor by default' do
    is_expected.to compile.with_all_deps
    is_expected.not_to contain_class('clamav::apparmor')
  end

  context 'with both confined validators enabled' do
    let(:params) { { manage_apparmor: true, manage_clamd: true, manage_freshclam: true } }

    it 'compiles without cycles and replaces the obsolete shared helper' do
      is_expected.to compile.with_all_deps
      is_expected.to contain_file('/usr/local/sbin/clamav-apparmor').with_source('puppet:///modules/clamav/apparmor')
      is_expected.to contain_file('/usr/local/sbin/clamav-freshclam-apparmor').with_ensure('absent')
                                                                              .that_comes_before('File[/usr/local/sbin/clamav-apparmor]')
    end

    {
      'freshclam' => 'usr.bin.freshclam',
      'clamd' => 'usr.sbin.clamd',
    }.each do |validator, profile|
      context "for #{validator}" do
        let(:config_parameter) { "#{validator}_config".to_sym }
        let(:local_path) { "/etc/apparmor.d/local/#{profile}" }
        let(:local_resource) { "clamav apparmor #{local_path}" }

        it 'loads its own narrow permission before native File validation' do
          is_expected.to contain_file(local_resource)
            .with_content(%r{^"/etc/clamav/#{validator}\.conf\*" r,$})
            .with_owner('root').with_group('root').with_mode('0644')
            .that_requires("Package[#{validator}]")
            .that_notifies("Exec[clamav-#{validator}-apparmor-reload]")
          is_expected.to contain_exec("clamav-#{validator}-apparmor-reload")
            .with_command(%r{^/usr/local/sbin/clamav-apparmor reload #{validator} })
            .with_refreshonly(true)
            .that_subscribes_to("Package[#{validator}]")
            .that_subscribes_to('File[/usr/local/sbin/clamav-apparmor]')
            .that_comes_before("Exec[clamav-#{validator}-apparmor-ready]")
          is_expected.to contain_exec("clamav-#{validator}-apparmor-ready")
            .with_unless(%r{^/usr/local/sbin/clamav-apparmor check #{validator} })
            .that_comes_before("File[#{validator}.conf]")
          is_expected.to contain_file("#{validator}.conf")
            .with_validate_cmd("/usr/bin/env #{validator} --config-file % --version")
          is_expected.not_to contain_file("/etc/apparmor.d/#{profile}")
        end

        context 'with a custom path and a managed parent directory' do
          let(:params) do
            super().merge(
              config_parameter => "/srv/clamav config/#{validator}.conf",
              managed_directories: [{ 'path' => '/srv/clamav config', 'owner' => 'root', 'group' => 'root', 'mode' => '0755' }],
            )
          end

          it do
            is_expected.to compile.with_all_deps
            is_expected.to contain_file(local_resource)
              .with_content(%r{^"/srv/clamav config/#{validator}\.conf\*" r,$})
              .that_requires('File[clamav managed directory /srv/clamav config]')
          end
        end

        ['*', '?', '[', '{', '"', '\\', "\n", '@', '../'].each do |character|
          context "with unsafe config path #{character.inspect}" do
            let(:params) { super().merge(config_parameter => "/etc/clamav/#{character}#{validator}.conf") }

            it { is_expected.to compile.and_raise_error(%r{#{validator}_config}) }
          end
        end

        context 'with caller content for the same profile' do
          let(:caller_profile) { { 'path' => local_path, 'content' => '/srv/database/ r,', 'ensure' => 'present' } }
          let(:params) { super().merge(apparmor_profiles: [caller_profile]) }

          it 'preserves the caller content and declares only one generated rule/file' do
            is_expected.to compile.with_all_deps
            content = catalogue.resource('File', local_resource)[:content]
            expect(content).to start_with("/srv/database/ r,\n")
            expect(content.scan("\"/etc/clamav/#{validator}.conf*\" r,").length).to eq(1)
            resources = catalogue.resources.select { |resource| resource.type == 'File' && resource[:path] == local_path }
            expect(resources.length).to eq(1)
          end

          context 'with duplicate ownership' do
            let(:params) { super().merge(apparmor_profiles: [caller_profile, caller_profile]) }

            it { is_expected.to compile.and_raise_error(%r{Only one apparmor_profiles entry}) }
          end

          context 'with conflicting removal' do
            let(:params) { super().merge(apparmor_profiles: [caller_profile.merge('ensure' => 'absent')]) }

            it { is_expected.to compile.and_raise_error(%r{cannot be absent}) }
          end
        end

        context 'with an overridden validator' do
          let(:params) { super().merge("#{validator}_config_validate_cmd".to_sym => "/opt/bin/#{validator} -c % -V") }

          it { is_expected.to contain_file("#{validator}.conf").with_validate_cmd("/opt/bin/#{validator} -c % -V") }
        end

        ["manage_#{validator}".to_sym, :validate_configs, :manage_apparmor].each do |setting|
          context "with #{setting} disabled" do
            let(:params) { super().merge(setting => false) }

            it do
              is_expected.to compile.with_all_deps
              is_expected.not_to contain_file(local_resource)
              is_expected.not_to contain_exec("clamav-#{validator}-apparmor-reload")
              is_expected.not_to contain_exec("clamav-#{validator}-apparmor-ready")
            end
          end
        end
      end
    end

    context 'without a separate Freshclam package or service' do
      let(:params) { super().merge(freshclam_package: nil, freshclam_service: nil) }

      it { is_expected.to compile.with_all_deps }
    end

    context 'with all four validators managed' do
      let(:params) do
        super().merge(
          manage_clamonacc: true,
          clamonacc_include_paths: ['/srv/scan'],
          clamonacc_exclude_usernames: ['clamav'],
          manage_clamav_milter: true,
          clamav_milter_package: 'clamav-milter',
          clamav_milter_version: 'installed',
          clamav_milter_config: '/etc/clamav/clamav-milter.conf',
          clamav_milter_service: 'clamav-milter',
          milter_default_options: { 'MilterSocket' => '/run/clamav/clamav-milter.ctl' },
        )
      end

      it 'does not invent policy for unconfined package binaries or disable their validators' do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file('clamav-milter.conf').with_validate_cmd('/usr/bin/env clamav-milter --config-file % --version')
        is_expected.to contain_file('clamonacc.conf').with_validate_cmd('/usr/bin/env clamonacc --config-file % --help')
        is_expected.not_to contain_file('clamav apparmor /etc/apparmor.d/local/usr.sbin.clamav-milter')
        is_expected.not_to contain_file('clamav apparmor /etc/apparmor.d/local/usr.sbin.clamonacc')
      end
    end
  end

  ['debian-12-x86_64', 'almalinux-9-x86_64'].each do |platform|
    context "with caller profiles on #{platform}" do
      let(:facts) { formally_supported_os_facts.fetch(platform) }
      let(:params) do
        {
          manage_apparmor: true, manage_clamd: true, manage_freshclam: true,
          apparmor_profiles: [{ 'path' => '/etc/caller-profile', 'content' => '# caller', 'ensure' => 'present' }],
        }
      end

      it do
        is_expected.to compile.with_all_deps
        is_expected.to contain_file('clamav apparmor /etc/caller-profile').with_content('# caller')
        is_expected.not_to contain_exec('clamav-freshclam-apparmor-reload')
        is_expected.not_to contain_exec('clamav-clamd-apparmor-reload')
        is_expected.not_to contain_file('/usr/local/sbin/clamav-apparmor')
        is_expected.not_to contain_file('/usr/local/sbin/clamav-freshclam-apparmor')
      end
    end
  end

  context 'with disabled AppArmor and a caller fragment' do
    let(:params) do
      { apparmor_profiles: [{ 'path' => '/etc/caller-profile', 'content' => '# caller', 'ensure' => 'present' }] }
    end

    it { is_expected.not_to contain_class('clamav::apparmor') }
  end

  context 'with an invalid caller profile path' do
    let(:params) do
      { manage_apparmor: true, apparmor_profiles: [{ 'path' => 'relative/profile', 'content' => '', 'ensure' => 'present' }] }
    end

    it { is_expected.to compile.and_raise_error(%r{apparmor_profiles}) }
  end
end
