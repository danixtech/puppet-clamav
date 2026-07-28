# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav on current Debian releases' do
  let(:release_major) { run_shell('facter os.release.major').stdout.strip }
  let(:evidence_prefix) { "debian_#{release_major}" }

  let(:common_parameters) do
    <<~PUPPET
      manage_repo      => false,
      manage_clamd     => true,
      manage_freshclam => true,
      clamd_default_options => {
        'DatabaseDirectory' => '/var/lib/clamav',
        'Foreground'        => false,
        'LocalSocket'       => '/run/clamav/clamd.ctl',
        'LocalSocketGroup'  => 'clamav',
        'LocalSocketMode'   => 660,
        'LogSyslog'         => true,
        'User'              => 'clamav',
      },
      freshclam_default_options => {
        'Checks'            => 1,
        'DatabaseDirectory' => '/var/lib/clamav',
        'DatabaseMirror'    => 'database.clamav.net',
        'DatabaseOwner'     => 'clamav',
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

  let(:direct_manifest) do
    <<~PUPPET
      class { 'clamav':
        #{common_parameters}
      }
    PUPPET
  end

  let(:socket_manifest) do
    <<~PUPPET
      class { 'clamav':
        #{common_parameters}
        clamd_use_socket => true,
        clamd_socket     => 'clamav-daemon.socket',
      }
    PUPPET
  end

  before(:each) do
    os_name = run_shell('facter os.name').stdout.strip
    skip 'Debian 12 and 13 targets only' unless os_name == 'Debian' && ['12', '13'].include?(release_major)
  end

  it 'records release-specific platform evidence' do
    expect(acceptance_evidence("#{evidence_prefix}_os_release", 'facter os.release.full')).to start_with(release_major)
    expect(acceptance_evidence("#{evidence_prefix}_puppet_version", 'puppet --version')).not_to be_empty
  end

  it 'installs packages and bootstraps official and local test databases' do
    apply_manifest(stopped_manifest, catch_failures: true)
    run_shell(
      "printf '%s\\n' '44d88612fea8a8f36de82e1278abb02f:68:Eicar-Test-Signature' " \
      '> /var/lib/clamav/local-test.hdb',
    )
    run_shell('chown clamav:clamav /var/lib/clamav/local-test.hdb')
    run_shell('chmod 0644 /var/lib/clamav/local-test.hdb')
    run_shell('freshclam --config-file=/etc/clamav/freshclam.conf')

    expect(acceptance_evidence("#{evidence_prefix}_clamav_package", "dpkg-query -W -f='${Version}' clamav")).not_to be_empty
    expect(acceptance_evidence("#{evidence_prefix}_clamd_package", "dpkg-query -W -f='${Version}' clamav-daemon")).not_to be_empty
    expect(acceptance_evidence("#{evidence_prefix}_freshclam_package", "dpkg-query -W -f='${Version}' clamav-freshclam")).not_to be_empty
  end

  it 'runs direct services with valid configuration and converges' do
    idempotent_apply(direct_manifest)

    expect(run_shell('systemctl is-active clamav-daemon').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-daemon').stdout.strip).to eq('enabled')
    expect(run_shell('systemctl is-active clamav-freshclam').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-freshclam').stdout.strip).to eq('enabled')
    expect(run_shell('clamd --config-file=/etc/clamav/clamd.conf --version').exit_code).to eq(0)
    expect(run_shell('freshclam --config-file=/etc/clamav/freshclam.conf --version').exit_code).to eq(0)
    expect(run_shell("grep -Fx 'LocalSocketMode 660' /etc/clamav/clamd.conf").exit_code).to eq(0)
    expect(run_shell("stat -c '%U' /run/clamav").stdout.strip).to eq('clamav')
  end

  it 'uses opt-in socket activation and detects a test signature' do
    idempotent_apply(socket_manifest)

    expect(run_shell('systemctl is-active clamav-daemon.socket').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-daemon.socket').stdout.strip).to eq('enabled')
    expect(run_shell('systemctl is-active clamav-daemon', expect_failures: true).stdout.strip).to eq('inactive')

    run_shell("printf '%s' 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.com")
    scan = run_shell('clamdscan --fdpass /tmp/eicar.com', expect_failures: true)
    expect(scan.exit_code).to eq(1)
    expect(scan.stdout).to match(%r{Eicar-Test-Signature.*FOUND})
  end

  it 'records database, service, and socket evidence' do
    expect(
      acceptance_evidence(
        "#{evidence_prefix}_database_files",
        "find /var/lib/clamav -maxdepth 1 -type f -printf '%f\\n' | sort | paste -sd, -",
      ),
    ).to include('local-test.hdb')
    expect(acceptance_evidence("#{evidence_prefix}_clamd_version", 'clamd --version')).not_to be_empty
    expect(
      acceptance_evidence(
        "#{evidence_prefix}_socket_unit",
        'systemctl show clamav-daemon.socket -p ActiveState -p UnitFileState',
      ),
    ).to include('ActiveState=active')
  end
end
