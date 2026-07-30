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
        'FIPSCryptoHashLimits' => true,
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
        'FIPSCryptoHashLimits' => true,
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
        freshclam_options => {
          'NotifyClamd' => '/etc/clamav/clamd.conf',
        },
      }
    PUPPET
  end

  let(:socket_manifest) do
    <<~PUPPET
      class { 'clamav':
        #{common_parameters}
        clamd_use_socket => true,
        clamd_socket     => 'clamav-daemon.socket',
        freshclam_options => {
          'NotifyClamd' => '/etc/clamav/clamd.conf',
        },
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
    expect(
      acceptance_evidence(
        'ubuntu_2404_clamav_package_policy',
        "apt-cache policy clamav | sed -n '1,8p'",
      ),
    ).to include('ubuntu')
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

    package_version = acceptance_evidence('ubuntu_2404_clamav_package', "dpkg-query -W -f='${Version}' clamav")
    expect(Gem::Version.new(package_version.split('+').first)).to be >= Gem::Version.new('1.5.0')
    expect(package_version).to include('ubuntu')
    expect(acceptance_evidence('ubuntu_2404_clamd_package', "dpkg-query -W -f='${Version}' clamav-daemon")).to eq(package_version)
    expect(acceptance_evidence('ubuntu_2404_freshclam_package', "dpkg-query -W -f='${Version}' clamav-freshclam")).to eq(package_version)
    expect(acceptance_evidence('ubuntu_2404_clamav_source_package', "dpkg-query -W -f='${source:Package}' clamav")).to eq('clamav')
  end

  it 'runs direct services with valid configuration and converges' do
    idempotent_apply(direct_manifest)

    expect(run_shell('systemctl is-active clamav-daemon').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-daemon').stdout.strip).to eq('enabled')
    expect(run_shell('systemctl is-active clamav-freshclam').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamav-freshclam').stdout.strip).to eq('enabled')
    expect(run_shell('clamd --config-file=/etc/clamav/clamd.conf --version').exit_code).to eq(0)
    expect(run_shell('freshclam --config-file=/etc/clamav/freshclam.conf --version').exit_code).to eq(0)
    expect(run_shell("grep -Fx 'FIPSCryptoHashLimits true' /etc/clamav/clamd.conf").exit_code).to eq(0)
    expect(run_shell("grep -Fx 'FIPSCryptoHashLimits true' /etc/clamav/freshclam.conf").exit_code).to eq(0)
    expect(run_shell("grep -Fx 'LocalSocketMode 660' /etc/clamav/clamd.conf").exit_code).to eq(0)
    expect(run_shell("stat -c '%U:%G %a' /run/clamav").stdout.strip).to eq('clamav:root 755')
    expect(run_shell("stat -c '%U:%G %a' /var/lib/clamav").stdout.strip).to eq('clamav:clamav 755')
    expect(run_shell("stat -c '%a' /run/clamav/clamd.ctl").stdout.strip).to eq('666')
    expect(run_shell('systemctl show clamav-daemon.service -p FragmentPath --value').stdout.strip).to end_with('/clamav-daemon.service')
    expect(run_shell('systemctl show clamav-freshclam.service -p FragmentPath --value').stdout.strip).to end_with('/clamav-freshclam.service')
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

  it 'updates a missing database and notifies clamd without restarting it' do
    apply_manifest(direct_manifest, catch_failures: true)
    run_shell('systemctl stop clamav-freshclam')
    clamd_pid = run_shell('systemctl show clamav-daemon -p MainPID --value').stdout.strip
    run_shell('rm -f /var/lib/clamav/daily.cvd /var/lib/clamav/daily-*.cvd.sign')

    update = run_shell('freshclam --config-file=/etc/clamav/freshclam.conf --stdout 2>&1')

    expect(update.stdout).to include('Clamd successfully notified about the update')
    expect(run_shell('systemctl is-active clamav-daemon').stdout.strip).to eq('active')
    expect(run_shell('systemctl show clamav-daemon -p MainPID --value').stdout.strip).to eq(clamd_pid)
    expect(run_shell('test -f /var/lib/clamav/daily.cvd').exit_code).to eq(0)
    expect(run_shell("find /var/lib/clamav -maxdepth 1 -name 'daily-*.cvd.sign' -print -quit | grep -q .").exit_code).to eq(0)
    run_shell('systemctl start clamav-freshclam')
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
    fips_state = acceptance_evidence(
      'ubuntu_2404_fips_state',
      "if test -r /proc/sys/crypto/fips_enabled; then cat /proc/sys/crypto/fips_enabled; else printf 'unavailable\\n'; fi",
    )
    expect(fips_state).to match(%r{\A(?:0|1|unavailable)\z})

    database_files = acceptance_evidence(
      'ubuntu_2404_database_files',
      "find /var/lib/clamav -maxdepth 1 -type f -printf '%f\\n' | sort | paste -sd, -",
    )
    expect(database_files).to include('main.cvd', 'daily.cvd', 'local-test.hdb')
    expect(database_files).to match(%r{(?:\A|,)main-\d+\.cvd\.sign(?:,|\z)})
    expect(database_files).to match(%r{(?:\A|,)daily-\d+\.cvd\.sign(?:,|\z)})
    expect(run_shell("find /var/lib/clamav -maxdepth 1 -type f \\( -name '*.cvd' -o -name '*.cld' -o -name '*.cvd.sign' \\) ! -user clamav -print -quit").stdout).to be_empty
    expect(run_shell("find /var/lib/clamav -maxdepth 1 -type f \\( -name '*.cvd' -o -name '*.cld' -o -name '*.cvd.sign' \\) -perm /022 -print -quit").stdout).to be_empty
    expect(run_shell('sigtool --info /var/lib/clamav/main.cvd').stdout).to include('Verification OK')
    expect(run_shell('sigtool --info /var/lib/clamav/daily.cvd').stdout).to include('Verification OK')

    run_shell('systemctl stop clamav-freshclam')
    no_op_update = run_shell('freshclam --config-file=/etc/clamav/freshclam.conf --stdout 2>&1')
    run_shell('systemctl start clamav-freshclam')
    expect(no_op_update.stdout).to include('is up-to-date')

    clamd_version = acceptance_evidence('ubuntu_2404_clamd_version', 'clamd --version')
    expect(Gem::Version.new(clamd_version.split[1].split('/').first)).to be >= Gem::Version.new('1.5.0')
    expect(
      acceptance_evidence(
        'ubuntu_2404_clamd_service_unit',
        'systemctl show clamav-daemon.service -p ActiveState -p UnitFileState -p FragmentPath',
      ),
    ).to include('ActiveState=active', 'FragmentPath=/usr/lib/systemd/system/clamav-daemon.service')
    expect(acceptance_evidence('ubuntu_2404_socket_unit', 'systemctl show clamav-daemon.socket -p ActiveState -p UnitFileState')).to include('ActiveState=active')
    expect(run_shell("systemctl cat clamav-daemon.socket | grep -F 'ListenStream=/run/clamav/clamd.ctl'").exit_code).to eq(0)
  end
end
