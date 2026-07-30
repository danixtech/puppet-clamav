# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav on AlmaLinux 9' do
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
    skip 'AlmaLinux 9 target only' unless os_name == 'AlmaLinux' && release == '9'
  end

  it 'records platform, repository, and SELinux evidence' do
    expect(acceptance_evidence('alma_9_os_release', 'facter os.release.full')).to start_with('9.')
    expect(acceptance_evidence('alma_9_puppet_version', 'puppet --version')).not_to be_empty
    expect(acceptance_evidence('alma_9_architecture', 'facter os.architecture')).not_to be_empty
    expect(acceptance_evidence('alma_9_selinux_enabled', 'facter selinux')).to match(%r{true|false})
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

    expect(acceptance_evidence('alma_9_enabled_repositories', 'dnf -q repolist --enabled')).to match(%r{\bepel\b})
    package_version = acceptance_evidence('alma_9_clamav_package', "rpm -q --qf '%{VERSION}-%{RELEASE}' clamav")
    expect(Gem::Version.new(package_version.split('-').first)).to be < Gem::Version.new('1.5.0')
    expect(
      acceptance_evidence(
        'alma_9_clamav_package_provenance',
        "rpm -q --qf '%{VENDOR}|%{PACKAGER}|%{SOURCERPM}' clamav",
      ),
    ).to include('clamav-')
    expect(
      acceptance_evidence('alma_9_clamd_provider', 'rpm -q --whatprovides clamav-scanner-systemd'),
    ).to match(%r{\Aclamd-})
    expect(
      acceptance_evidence('alma_9_freshclam_provider', 'rpm -q --whatprovides clamav-update'),
    ).to match(%r{\Aclamav-freshclam-})
    expect(acceptance_evidence('alma_9_clamav_repository', 'dnf -q info installed clamav')).to match(%r{From repo\s+:\s+epel})
    expect(acceptance_evidence('alma_9_clamscan_path', 'command -v clamscan')).to eq('/usr/bin/clamscan')
    expect(acceptance_evidence('alma_9_clamd_path', 'command -v clamd')).to eq('/usr/sbin/clamd')
    expect(acceptance_evidence('alma_9_freshclam_path', 'command -v freshclam')).to eq('/usr/bin/freshclam')
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
    expect(run_shell('systemctl show clamd@scan -p FragmentPath --value').stdout.strip).to eq('/usr/lib/systemd/system/clamd@.service')
    expect(run_shell('systemctl show clamav-freshclam -p FragmentPath --value').stdout.strip).to eq('/usr/lib/systemd/system/clamav-freshclam.service')
  end

  it 'detects a deterministic test signature through clamd' do
    run_shell("printf '%s' 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.com")
    scan = run_shell('clamdscan --fdpass --config-file=/etc/clamd.d/scan.conf /tmp/eicar.com', expect_failures: true)
    expect(scan.exit_code).to eq(1)
    expect(scan.stdout).to match(%r{Eicar-Test-Signature.*FOUND})
  end

  it 'records database, service, and runtime-path evidence' do
    database_files = acceptance_evidence(
      'alma_9_database_files',
      "find /var/lib/clamav -maxdepth 1 -type f -printf '%f\\n' | sort | paste -sd, -",
    )
    expect(database_files).to include('main.cvd', 'local-test.hdb')
    expect(database_files).to match(%r{daily\.c[lv]d})
    expect(run_shell("find /var/lib/clamav -maxdepth 1 -type f \\( -name '*.cvd' -o -name '*.cld' \\) ! -user clamupdate -print -quit").stdout).to be_empty
    expect(run_shell("find /var/lib/clamav -maxdepth 1 -type f \\( -name '*.cvd' -o -name '*.cld' \\) -perm /022 -print -quit").stdout).to be_empty
    expect(run_shell('sigtool --info /var/lib/clamav/main.cvd').stdout).to include('Verification OK')

    run_shell('systemctl stop clamav-freshclam')
    no_op_update = run_shell('freshclam --config-file=/etc/freshclam.conf --stdout 2>&1')
    run_shell('systemctl start clamav-freshclam')
    expect(no_op_update.stdout).to include('is up-to-date')

    clamd_version = acceptance_evidence('alma_9_clamd_version', 'clamd --version')
    expect(Gem::Version.new(clamd_version.split[1].split('/').first)).to be < Gem::Version.new('1.5.0')
    expect(acceptance_evidence('alma_9_freshclam_version', 'freshclam --version')).not_to be_empty
    expect(acceptance_evidence('alma_9_service_unit', 'systemctl show clamd@scan -p ActiveState -p UnitFileState')).to include('ActiveState=active')
    expect(acceptance_evidence('alma_9_socket_mode', "stat -c '%a' /run/clamd.scan/clamd.sock")).to eq('660')
  end
end
