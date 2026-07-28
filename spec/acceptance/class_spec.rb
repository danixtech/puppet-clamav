# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav smoke acceptance' do
  let(:manifest) do
    <<~MANIFEST
      class { 'clamav':
        manage_repo              => false,
        manage_clamd             => true,
        manage_freshclam         => true,
        clamd_service_ensure     => 'stopped',
        clamd_service_enable     => false,
        freshclam_service_ensure => 'stopped',
        freshclam_service_enable => false,
      }
    MANIFEST
  end

  before(:all) do
    acceptance_evidence('puppet_version', 'puppet --version')
    acceptance_evidence('os_name', 'facter os.name')
    acceptance_evidence('os_release', 'facter os.release.full')
  end

  before(:each) do
    os_name = run_shell('facter os.name').stdout.strip
    release = run_shell('facter os.release.full').stdout.strip
    skip 'Ubuntu 22.04 smoke target only' unless os_name == 'Ubuntu' && release.start_with?('22.04')
  end

  it 'applies twice without failures or second-run changes' do
    idempotent_apply(manifest)
  end

  describe package('clamav') do
    it { is_expected.to be_installed }
  end

  describe package('clamav-daemon') do
    it { is_expected.to be_installed }
  end

  describe package('clamav-freshclam') do
    it { is_expected.to be_installed }
  end

  describe file('/etc/clamav/clamd.conf') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode 644 }
  end

  describe file('/etc/clamav/freshclam.conf') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'root' }
    it { is_expected.to be_grouped_into 'root' }
    it { is_expected.to be_mode 644 }
  end

  describe file('/var/lib/clamav') do
    it { is_expected.to be_directory }
  end

  describe service('clamav-daemon') do
    it { is_expected.not_to be_enabled }
    it { is_expected.not_to be_running }
  end

  describe service('clamav-freshclam') do
    it { is_expected.not_to be_enabled }
    it { is_expected.not_to be_running }
  end

  describe command('clamd --config-file=/etc/clamav/clamd.conf --version') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  describe command('freshclam --config-file=/etc/clamav/freshclam.conf --version') do
    its(:exit_status) { is_expected.to eq 0 }
  end

  it 'reports installed ClamAV versions and database state' do
    expect(acceptance_evidence('clamd_version', 'clamd --version')).not_to be_empty
    expect(acceptance_evidence('freshclam_version', 'freshclam --version')).not_to be_empty
    expect(
      acceptance_evidence(
        'database_files',
        "find /var/lib/clamav -maxdepth 1 -type f -printf '%f\\n' | sort | paste -sd, -",
      ),
    ).to be_a(String)
  end
end
