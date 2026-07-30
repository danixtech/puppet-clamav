require 'spec_helper'

supported_os = on_supported_os
debian_facts = supported_os.fetch('debian-12-x86_64')
redhat_facts = supported_os.fetch('almalinux-9-x86_64')

describe 'clamav', type: :class do
  context 'on Debian with every component managed' do
    let(:facts) { debian_facts }
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        manage_clamav_milter: true,
        clamav_milter_package: 'clamav-milter',
        clamav_milter_version: 'installed',
        clamav_milter_config: '/etc/clamav/clamav-milter.conf',
        clamav_milter_service: 'clamav-milter',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it 'validates candidate files with their package-provided binaries' do
      is_expected.to contain_file('clamd.conf')
        .with_validate_cmd('/usr/bin/env clamd --config-file % --version')
      is_expected.to contain_file('freshclam.conf')
        .with_validate_cmd('/usr/bin/env freshclam --config-file % --version')
      is_expected.to contain_file('clamav-milter.conf')
        .with_validate_cmd('/usr/bin/env clamav-milter --config-file % --version')
    end

    it 'installs each validator before validating its candidate file' do
      is_expected.to contain_package('clamd').that_comes_before('File[clamd.conf]')
      is_expected.to contain_package('freshclam').that_comes_before('File[freshclam.conf]')
      is_expected.to contain_package('clamav_milter').that_comes_before('File[clamav-milter.conf]')
    end

    it 'retains configuration subscriptions after adding preflight validation' do
      is_expected.to contain_service('clamd').that_subscribes_to('File[clamd.conf]')
      is_expected.to contain_service('freshclam').that_subscribes_to('File[freshclam.conf]')
      is_expected.to contain_service('clamav_milter').that_subscribes_to('File[clamav-milter.conf]')
    end
  end

  context 'with caller-supplied validation commands' do
    let(:facts) { redhat_facts }
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        clamd_config_validate_cmd: '/opt/clamav/bin/clamd -c % -V',
        freshclam_config_validate_cmd: '/opt/clamav/bin/freshclam --config-file=% --version',
      }
    end

    it 'uses the caller commands verbatim' do
      is_expected.to contain_file('clamd.conf')
        .with_validate_cmd('/opt/clamav/bin/clamd -c % -V')
      is_expected.to contain_file('freshclam.conf')
        .with_validate_cmd('/opt/clamav/bin/freshclam --config-file=% --version')
    end
  end

  context 'with validation explicitly disabled' do
    let(:facts) { debian_facts }
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        manage_clamav_milter: true,
        clamav_milter_package: 'clamav-milter',
        clamav_milter_version: 'installed',
        clamav_milter_config: '/etc/clamav/clamav-milter.conf',
        clamav_milter_service: 'clamav-milter',
        validate_configs: false,
      }
    end

    it 'leaves validation unset on all managed files' do
      expect(catalogue.resource('File', 'clamd.conf')[:validate_cmd]).to be_nil
      expect(catalogue.resource('File', 'freshclam.conf')[:validate_cmd]).to be_nil
      expect(catalogue.resource('File', 'clamav-milter.conf')[:validate_cmd]).to be_nil
    end
  end
end
