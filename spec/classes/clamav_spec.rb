require 'spec_helper'

describe 'clamav', type: :class do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      let(:pre_condition) do
        'class epel {}' if facts[:osfamily] == 'RedHat'
      end

      context 'with defaults' do
        it { is_expected.to compile.with_all_deps }
        if facts[:osfamily] == 'RedHat'
          it { is_expected.to contain_class('epel') }
        elsif facts[:osfamily] == 'Debian'
          it { is_expected.not_to contain_class('epel') }
        end
        it { is_expected.not_to contain_class('clamav::user') }
        it { is_expected.to contain_class('clamav::install') }
        it { is_expected.not_to contain_class('clamav::clamd') }
        it { is_expected.not_to contain_class('clamav::freshclam') }
      end

      context 'manage user' do
        let(:params) { { manage_user: true } }

        it { is_expected.to contain_class('clamav::user') }
      end

      context 'disable epel on RedHat' do
        let(:params) { { manage_repo: false } }

        it { is_expected.not_to contain_class('epel') }
      end

      context 'manage clamd and freshclam' do
        let(:params) { { manage_clamd: true, manage_freshclam: true } }

        it { is_expected.to contain_class('clamav::clamd') }
        it { is_expected.to contain_class('clamav::freshclam') }
      end

      context 'manage clamav_milter' do
        if facts[:osfamily] == 'RedHat' && facts[:operatingsystemrelease] >= '7.0'
          let(:params) { { manage_clamav_milter: true } }

          it { is_expected.to contain_class('clamav::clamav_milter') }
        end
      end

      context 'clamav::user' do
        let(:params) { { manage_user: true } }

        context 'with defaults' do
          it { is_expected.to contain_group('clamav') }
          it { is_expected.to contain_user('clamav') }
        end
        context 'disable group and user' do
          let(:params) { { manage_user: true, group: false, user: false } }

          it { is_expected.not_to contain_group('clamav') }
          it { is_expected.not_to contain_user('clamav') }
        end
      end

      context 'clamav::install' do
        context 'with defaults' do
          it { is_expected.to contain_package('clamav') }
        end
      end

      context 'clamav::clamd' do
        let(:params) { { manage_clamd: true } }

        context 'with defaults' do
          if facts[:osfamily] == 'RedHat'
            it do
              is_expected.to contain_package('clamav-scanner-systemd')
                .with_ensure('latest')
                .that_comes_before('File[/etc/clamd.d/scan.conf]')
            end

            it do
              is_expected.to contain_file('/etc/clamd.d/scan.conf').with(
                owner: 'clamscan',
                group: 'clamscan',
                mode: '0644',
              )
            end

            it do
              is_expected.to contain_service('clamd@scan')
                .that_subscribes_to('Package[clamav-scanner-systemd]')
                .that_subscribes_to('File[/etc/clamd.d/scan.conf]')
            end
          elsif facts[:osfamily] == 'Debian'
            it do
              is_expected.to contain_package('clamav-daemon')
                .with_ensure('latest')
                .that_comes_before('File[/etc/clamav/clamd.conf]')
            end

            it do
              is_expected.to contain_file('/etc/clamav/clamd.conf').with(
                owner: 'clamav',
                group: 'clamav',
                mode: '0644',
              )
            end

            it do
              is_expected.to contain_service('clamav-daemon')
                .with(ensure: 'running', enable: true)
                .that_subscribes_to('Package[clamav-daemon]')
                .that_subscribes_to('File[/etc/clamav/clamd.conf]')
            end
          end
        end
      end

      context 'clamav::freshclam' do
        let(:params) { { manage_freshclam: true } }

        context 'with defaults' do
          if facts[:osfamily] == 'RedHat'
            it do
              is_expected.to contain_package('clamav-update')
                .with_ensure('latest')
                .that_comes_before('File[/etc/freshclam.conf]')
            end

            it do
              is_expected.to contain_file('/etc/sysconfig/freshclam').with(
                owner: 'root',
                group: 'root',
                mode: '0644',
              ).with_content(%r{^FRESHCLAM_DELAY=0$}m)
            end

            it do
              config = contain_file('/etc/freshclam.conf').with(
                owner: 'clamscan',
                group: 'clamscan',
                mode: '0644',
              )

              if facts[:operatingsystemmajrelease].to_i >= 8
                config = config.that_notifies('Service[clamav-freshclam]')
              end

              is_expected.to config
            end

            if facts[:operatingsystemmajrelease].to_i >= 8
              it do
                is_expected.to contain_service('clamav-freshclam')
                  .with(ensure: 'running', enable: true)
                  .that_subscribes_to('Package[clamav-update]')
                  .that_subscribes_to('File[/etc/freshclam.conf]')
                  .that_subscribes_to('File[/etc/sysconfig/freshclam]')
              end
            else
              it { is_expected.not_to contain_service('clamav-freshclam') }
            end
          elsif facts[:osfamily] == 'Debian'
            it do
              is_expected.to contain_package('clamav-freshclam')
                .with_ensure('latest')
                .that_comes_before('File[/etc/clamav/freshclam.conf]')
            end

            it do
              is_expected.to contain_file('/etc/clamav/freshclam.conf').with(
                owner: 'clamav',
                group: 'clamav',
                mode: '0644',
              ).that_notifies('Service[clamav-freshclam]')
            end

            it do
              is_expected.to contain_service('clamav-freshclam')
                .with(ensure: 'running', enable: true)
                .that_subscribes_to('Package[clamav-freshclam]')
                .that_subscribes_to('File[/etc/clamav/freshclam.conf]')
            end

            it { is_expected.not_to contain_file('/etc/default/freshclam') }
          end
        end
      end
    end
  end
end
