# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav smoke acceptance' do
  let(:manifest) do
    <<~MANIFEST
      class { 'clamav':
        manage_repo      => false,
        manage_clamd     => true,
        manage_freshclam => true,
      }
    MANIFEST
  end

  before(:all) do
    acceptance_evidence('puppet_version', 'puppet --version')
    acceptance_evidence('os_name', 'facter os.name')
    acceptance_evidence('os_release', 'facter os.release.full')
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

  describe file('/var/run/clamav') do
    it { is_expected.to be_directory }
  end

  describe service('clamav-daemon') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
  end

  describe service('clamav-freshclam') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running }
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
