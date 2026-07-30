# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav on Ubuntu 24.04' do
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
    release = run_shell('facter os.release.full').stdout.strip
    skip 'Ubuntu 24.04 target only' unless release.start_with?('24.04')
  end

  it 'records platform and repository package evidence' do
    expect(acceptance_evidence('ubuntu_2404_os_release', 'facter os.release.full')).to start_with('24.04')
    expect(acceptance_evidence('ubuntu_2404_puppet_version', 'puppet --version')).not_to be_empty
  end

  it 'installs packages and bootstraps a deterministic local test database' do
    apply_manifest(stopped_manifest, catch_failures: true)
    run_shell(
      "printf '%s\\n' '44d88612fea8a8f36de82e1278abb02f:68:Eicar-Test-Signature' " \
      '> /var/lib/clamav/local-test.hdb',
    )
    run_shell('chown clamav:clamav /var/lib/clamav/local-test.hdb')
    run_shell('chmod 0644 /var/lib/clamav/local-test.hdb')
    run_shell('freshclam --config-file=/etc/clamav/freshclam.conf')

    expect(acceptance_evidence('ubuntu_2404_clamav_package', "dpkg-query -W -f='${Version}' clamav")).not_to be_empty
    expect(acceptance_evidence('ubuntu_2404_clamd_package', "dpkg-query -W -f='${Version}' clamav-daemon")).not_to be_empty
    expect(acceptance_evidence('ubuntu_2404_freshclam_package', "dpkg-query -W -f='${Version}' clamav-freshclam")).not_to be_empty
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
    expect(run_shell("stat -c '%a' /run/clamav/clamd.ctl").stdout.strip).to eq('666')
  end

  it 'rejects invalid candidate configuration before replacing or refreshing clamd' do
    apply_manifest(direct_manifest, catch_failures: true)
    before_digest = run_shell('sha256sum /etc/clamav/clamd.conf').stdout.split.first

    invalid_manifest = <<~PUPPET
      class { 'clamav':
        #{common_parameters}
        clamd_options => {
          'DefinitelyInvalidDirective' => true,
        },
      }
    PUPPET

    apply_manifest(invalid_manifest, expect_failures: true)

    expect(run_shell('sha256sum /etc/clamav/clamd.conf').stdout.split.first).to eq(before_digest)
    expect(run_shell('systemctl is-active clamav-daemon').stdout.strip).to eq('active')
  end

  it 'uses opt-in socket activation and characterizes the distro socket mode' do
    idempotent_apply(socket_manifest)

    expect(run_shell('systemctl is-active clamav-daemon.socket').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-daemon.socket').stdout.strip).to eq('enabled')
    expect(run_shell('systemctl is-active clamav-daemon', expect_failures: true).stdout.strip).to eq('inactive')

    run_shell("printf '%s' 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > /tmp/eicar.com")
    scan = run_shell('clamdscan --fdpass /tmp/eicar.com', expect_failures: true)
    expect(scan.exit_code).to eq(1)
    expect(scan.stdout).to match(%r{Eicar-Test-Signature.*FOUND})
    expect(run_shell("stat -c '%a' /run/clamav/clamd.ctl").stdout.strip).to eq('666')
  end

  it 'records database and service evidence' do
    expect(
      acceptance_evidence(
        'ubuntu_2404_database_files',
        "find /var/lib/clamav -maxdepth 1 -type f -printf '%f\\n' | sort | paste -sd, -",
      ),
    ).to include('local-test.hdb')
    expect(acceptance_evidence('ubuntu_2404_clamd_version', 'clamd --version')).not_to be_empty
    expect(acceptance_evidence('ubuntu_2404_socket_unit', 'systemctl show clamav-daemon.socket -p ActiveState -p UnitFileState')).to include('ActiveState=active')
  end
end
