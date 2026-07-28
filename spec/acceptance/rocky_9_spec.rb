# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav on Rocky Linux 9' do
  let(:common_parameters) do
    <<~PUPPET
      manage_repo      => true,
      manage_clamd     => true,
      manage_freshclam => true,
      clamd_default_options => {
        'DatabaseDirectory' => '/var/lib/clamav',
        'Foreground'        => false,
        'LocalSocket'       => '/run/clamd.scan/clamd.sock',
        'LocalSocketGroup'  => 'clamscan',
        'LocalSocketMode'   => 660,
        'LogSyslog'         => true,
        'User'              => 'clamscan',
      },
      freshclam_default_options => {
        'Checks'            => 1,
        'DatabaseDirectory' => '/var/lib/clamav',
        'DatabaseMirror'    => 'database.clamav.net',
        'DatabaseOwner'     => 'clamupdate',
        'Foreground'        => false,
        'LogSyslog'         => true,
      },
    PUPPET
  end

  let(:stopped_manifest) do
    <<~PUPPET
      class { 'clamav':
        #{common_parameters}
        clamd_service_ensure     => 'stopped',
        clamd_service_enable     => false,
        freshclam_service_ensure => 'stopped',
        freshclam_service_enable => false,
      }
    PUPPET
  end

  let(:running_manifest) do
    <<~PUPPET
      class { 'clamav':
        #{common_parameters}
      }
    PUPPET
  end

  before(:each) do
    os_name = run_shell('facter os.name').stdout.strip
    release = run_shell('facter os.release.major').stdout.strip
    skip 'Rocky Linux 9 target only' unless os_name == 'Rocky' && release == '9'
  end

  it 'records platform, repository, and SELinux evidence' do
    expect(acceptance_evidence('rocky_9_os_release', 'facter os.release.full')).to start_with('9.')
    expect(acceptance_evidence('rocky_9_puppet_version', 'puppet --version')).not_to be_empty
    expect(acceptance_evidence('rocky_9_architecture', 'facter os.architecture')).not_to be_empty
    expect(acceptance_evidence('rocky_9_selinux_enabled', 'facter selinux')).to match(%r{true|false})
  end

  it 'installs EPEL packages and bootstraps official and local databases' do
    apply_manifest(stopped_manifest, catch_failures: true)
    run_shell(
      "printf '%s\\n' '44d88612fea8a8f36de82e1278abb02f:68:Eicar-Test-Signature' " \
      '> /var/lib/clamav/local-test.hdb',
    )
    run_shell('chown clamupdate:clamupdate /var/lib/clamav/local-test.hdb')
    run_shell('chmod 0644 /var/lib/clamav/local-test.hdb')
    run_shell('freshclam --config-file=/etc/freshclam.conf')

    expect(acceptance_evidence('rocky_9_enabled_repositories', 'dnf -q repolist --enabled')).to match(%r{\bepel\b})
    expect(acceptance_evidence('rocky_9_clamav_package', "rpm -q --qf '%{VERSION}-%{RELEASE}' clamav")).not_to be_empty
    expect(
      acceptance_evidence('rocky_9_clamd_provider', 'rpm -q --whatprovides clamav-scanner-systemd'),
    ).to match(%r{\Aclamd-})
    expect(
      acceptance_evidence('rocky_9_freshclam_provider', 'rpm -q --whatprovides clamav-update'),
    ).to match(%r{\Aclamav-freshclam-})
    expect(acceptance_evidence('rocky_9_clamav_repository', 'dnf -q info installed clamav')).to match(%r{From repo\s+:\s+epel})
  end

  it 'runs clamd and freshclam with valid configuration and converges' do
    idempotent_apply(running_manifest)

    expect(run_shell('systemctl is-active clamd@scan').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamd@scan').stdout.strip).to eq('enabled')
    expect(run_shell('systemctl is-active clamav-freshclam').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-freshclam').stdout.strip).to eq('enabled')
    expect(run_shell('clamd --config-file=/etc/clamd.d/scan.conf --version').exit_code).to eq(0)
    expect(run_shell('freshclam --config-file=/etc/freshclam.conf --version').exit_code).to eq(0)
    expect(run_shell("grep -Fx 'LocalSocketMode 660' /etc/clamd.d/scan.conf").exit_code).to eq(0)
    expect(run_shell("stat -c '%U:%G' /run/clamd.scan").stdout.strip).to eq('clamscan:virusgroup')
  end

  it 'detects a deterministic test signature through clamd' do
    run_shell("printf '%s' 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.com")
    scan = run_shell('clamdscan --fdpass --config-file=/etc/clamd.d/scan.conf /tmp/eicar.com', expect_failures: true)
    expect(scan.exit_code).to eq(1)
    expect(scan.stdout).to match(%r{Eicar-Test-Signature.*FOUND})
  end

  it 'records database, service, and runtime-path evidence' do
    expect(
      acceptance_evidence(
        'rocky_9_database_files',
        "find /var/lib/clamav -maxdepth 1 -type f -printf '%f\\n' | sort | paste -sd, -",
      ),
    ).to include('local-test.hdb')
    expect(acceptance_evidence('rocky_9_clamd_version', 'clamd --version')).not_to be_empty
    expect(acceptance_evidence('rocky_9_service_unit', 'systemctl show clamd@scan -p ActiveState -p UnitFileState')).to include('ActiveState=active')
    expect(acceptance_evidence('rocky_9_socket_mode', "stat -c '%a' /run/clamd.scan/clamd.sock")).to eq('660')
  end
end
