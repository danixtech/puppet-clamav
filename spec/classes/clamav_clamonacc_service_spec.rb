require 'spec_helper'

# rubocop:disable RSpec/MultipleDescribes

debian_12_facts = on_supported_os.fetch('debian-12-x86_64')

describe 'clamav', type: :class do
  let(:facts) { debian_12_facts }

  context 'with a package-native clamonacc service' do
    let(:params) do
      {
        manage_clamd: true,
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_service: 'clamav-clamonacc',
        clamonacc_include_paths: ['/srv/data'],
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_service('clamonacc').with(
        name: 'clamav-clamonacc',
        ensure: 'running',
        enable: true,
        hasrestart: true,
        hasstatus: true,
        subscribe: 'File[clamonacc.conf]',
      )
    end

    it { is_expected.not_to contain_package('clamonacc') }
    it { is_expected.not_to contain_file('clamonacc.service') }
    it { is_expected.not_to contain_exec('clamonacc-systemd-daemon-reload') }

    it 'orders clamd before clamonacc' do
      is_expected.to contain_class('clamav::clamd')
        .that_comes_before('Class[clamav::clamonacc]')
    end
  end

  context 'with a separately packaged clamonacc service' do
    let(:params) do
      {
        manage_clamd: true,
        manage_clamonacc: true,
        clamonacc_package: 'clamav-onaccess',
        clamonacc_package_version: '1.5.3',
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_service: 'clamav-clamonacc',
        clamonacc_include_paths: ['/srv/data'],
      }
    end

    it do
      is_expected.to contain_package('clamonacc').with(
        name: 'clamav-onaccess',
        ensure: '1.5.3',
      )
    end

    it { is_expected.to contain_package('clamonacc').that_comes_before('File[clamonacc.conf]') }
    it { is_expected.to contain_service('clamonacc').that_subscribes_to('Package[clamonacc]') }
  end

  context 'with a module-managed systemd unit' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_binary: '/usr/sbin/clamonacc',
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_service: 'clamav-onaccess',
        clamonacc_manage_service_unit: true,
        clamonacc_service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
        clamonacc_include_paths: ['/srv/data'],
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_file('clamonacc.service').with(
        path: '/etc/systemd/system/clamav-onaccess.service',
        owner: 'root',
        group: 'root',
        mode: '0644',
      )
    end

    it 'renders resolved paths and clamd ordering in the unit' do
      is_expected.to contain_file('clamonacc.service')
        .with_content(%r{^After=clamav-daemon\.service$}m)
        .with_content(%r{^Requires=clamav-daemon\.service$}m)
        .with_content(%r{^ExecStart=/usr/sbin/clamonacc --config-file=/etc/clamav/clamonacc\.conf --foreground$}m)
        .with_content(%r{^Restart=on-failure$}m)
        .with_content(%r{^WantedBy=multi-user\.target$}m)
    end

    it do
      is_expected.to contain_exec('clamonacc-systemd-daemon-reload').with(
        command: '/usr/bin/systemctl daemon-reload',
        refreshonly: true,
      )
    end

    it { is_expected.to contain_file('clamonacc.service').that_notifies('Exec[clamonacc-systemd-daemon-reload]') }
    it { is_expected.to contain_exec('clamonacc-systemd-daemon-reload').that_comes_before('Service[clamonacc]') }
    it { is_expected.to contain_service('clamonacc').that_subscribes_to('File[clamonacc.service]') }
  end

  context 'with native quarantine enabled' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_binary: '/usr/sbin/clamonacc',
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_service: 'clamav-onaccess',
        clamonacc_manage_service_unit: true,
        clamonacc_service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
        clamonacc_include_paths: ['/srv/data'],
        clamonacc_exclude_paths: ['/srv/quarantine'],
        clamonacc_manage_quarantine: true,
        clamonacc_quarantine_path: '/srv/quarantine',
        clamonacc_quarantine_owner: 'scanner',
        clamonacc_quarantine_group: 'scanner',
        clamonacc_quarantine_mode: '0750',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_file('clamonacc quarantine directory').with(
        ensure: 'directory',
        path: '/srv/quarantine',
        owner: 'scanner',
        group: 'scanner',
        mode: '0750',
      )
    end

    it { is_expected.to contain_file('clamonacc quarantine directory').that_comes_before('Service[clamonacc]') }
    it { is_expected.to contain_file('clamonacc.service').with_content(%r{ --move=/srv/quarantine$}m) }
  end

  context 'with optional temporary-directory management' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_include_paths: ['/srv/data'],
        clamonacc_temporary_directory: '/var/tmp/clamonacc',
        clamonacc_manage_temporary_directory: true,
        clamonacc_temporary_directory_owner: 'clamav',
        clamonacc_temporary_directory_group: 'clamav',
        clamonacc_temporary_directory_mode: '0750',
      }
    end

    it do
      is_expected.to contain_file('clamonacc temporary directory').with(
        ensure: 'directory',
        path: '/var/tmp/clamonacc',
        owner: 'clamav',
        group: 'clamav',
        mode: '0750',
      )
    end

    it { is_expected.to contain_file('clamonacc temporary directory').that_comes_before('File[clamonacc.conf]') }
  end

  context 'with clamonacc explicitly stopped and disabled' do
    let(:params) do
      {
        manage_clamonacc: true,
        clamonacc_config: '/etc/clamav/clamonacc.conf',
        clamonacc_service: 'clamav-clamonacc',
        clamonacc_service_ensure: 'stopped',
        clamonacc_service_enable: false,
        clamonacc_include_paths: ['/srv/data'],
      }
    end

    it { is_expected.to contain_service('clamonacc').with(ensure: 'stopped', enable: false) }
  end

  context 'with clamonacc disabled and service inputs present' do
    let(:params) do
      {
        manage_clamonacc: false,
        clamonacc_package: 'clamav-onaccess',
        clamonacc_service: 'clamav-clamonacc',
        clamonacc_manage_service_unit: true,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_package('clamonacc') }
    it { is_expected.not_to contain_file('clamonacc.service') }
    it { is_expected.not_to contain_service('clamonacc') }
  end
end

describe 'clamav::clamonacc', type: :class do
  let(:facts) { debian_12_facts }
  let(:base_params) do
    {
      config_path: '/etc/clamav/clamonacc.conf',
      local_socket: '/run/clamav/clamd.ctl',
      include_paths: ['/srv/data'],
    }
  end

  context 'with a directly declared package-native service' do
    let(:params) { base_params.merge(service_name: 'clamav-clamonacc') }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_service('clamonacc').with_name('clamav-clamonacc') }
  end

  context 'when a custom unit lacks a binary path' do
    let(:params) do
      base_params.merge(
        service_name: 'clamav-onaccess',
        manage_service_unit: true,
        service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
        daemon_service_name: 'clamav-daemon',
      )
    end

    it { is_expected.to compile.and_raise_error(%r{managed service unit requires binary_path}) }
  end

  context 'when a custom unit lacks a unit path' do
    let(:params) do
      base_params.merge(
        binary_path: '/usr/sbin/clamonacc',
        service_name: 'clamav-onaccess',
        manage_service_unit: true,
        daemon_service_name: 'clamav-daemon',
      )
    end

    it { is_expected.to compile.and_raise_error(%r{managed service unit requires service_unit_path}) }
  end

  context 'when a custom unit lacks a clamd service name' do
    let(:params) do
      base_params.merge(
        binary_path: '/usr/sbin/clamonacc',
        service_name: 'clamav-onaccess',
        manage_service_unit: true,
        service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
      )
    end

    it { is_expected.to compile.and_raise_error(%r{managed service unit requires daemon_service_name}) }
  end

  context 'when unit management is requested without a service name' do
    let(:params) do
      base_params.merge(
        binary_path: '/usr/sbin/clamonacc',
        manage_service_unit: true,
        service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
        daemon_service_name: 'clamav-daemon',
      )
    end

    it { is_expected.to compile.and_raise_error(%r{managed service unit requires service_name}) }
  end

  context 'when quarantine is requested without a path' do
    let(:params) do
      base_params.merge(
        binary_path: '/usr/sbin/clamonacc',
        service_name: 'clamav-onaccess',
        manage_service_unit: true,
        service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
        daemon_service_name: 'clamav-daemon',
        manage_quarantine: true,
      )
    end

    it { is_expected.to compile.and_raise_error(%r{quarantine management requires quarantine_path}) }
  end

  context 'when quarantine is requested for a package-native unit' do
    let(:params) do
      base_params.merge(
        service_name: 'clamav-onaccess',
        quarantine_path: '/srv/quarantine',
        manage_quarantine: true,
      )
    end

    it { is_expected.to compile.and_raise_error(%r{native quarantine requires manage_service_unit}) }
  end

  context 'when quarantine is not excluded from on-access scanning' do
    let(:params) do
      base_params.merge(
        binary_path: '/usr/sbin/clamonacc',
        service_name: 'clamav-onaccess',
        manage_service_unit: true,
        service_unit_path: '/etc/systemd/system/clamav-onaccess.service',
        daemon_service_name: 'clamav-daemon',
        quarantine_path: '/srv/quarantine',
        manage_quarantine: true,
      )
    end

    it { is_expected.to compile.and_raise_error(%r{quarantine_path must also be present in exclude_paths}) }
  end

  context 'when temporary-directory management lacks a path' do
    let(:params) { base_params.merge(manage_temporary_directory: true) }

    it { is_expected.to compile.and_raise_error(%r{temporary-directory management requires temporary_directory}) }
  end
end

# rubocop:enable RSpec/MultipleDescribes
