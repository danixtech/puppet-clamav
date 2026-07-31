# frozen_string_literal: true

require 'spec_helper_acceptance'
require 'base64'

describe 'clamonacc on-access runtime' do
  let(:eicar_content) do
    'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
  end

  def supported_target?
    os_name = run_shell('facter os.name').stdout.strip
    release = run_shell('facter os.release.major').stdout.strip

    (os_name == 'Ubuntu' && release == '24') ||
      (os_name == 'Debian' && release == '12') ||
      (os_name == 'AlmaLinux' && release == '9')
  end

  def runtime_manifest(extra_exclude_path = nil)
    exclude_paths = [
      '/tmp/clamonacc-runtime-excluded',
      '/tmp/clamonacc-runtime-quarantine',
    ]
    exclude_paths << extra_exclude_path unless extra_exclude_path.nil?
    rendered_excludes = exclude_paths.map { |path| "'#{path}'" }.join(', ')

    <<~PUPPET
      if $facts['os']['family'] == 'RedHat' {
        class { 'epel': }
        $runtime_daemon_package = 'clamd'
        $runtime_daemon_user = 'clamscan'
        $runtime_daemon_group = 'clamscan'

        Class['epel']
          -> Package['clamonacc runtime client']
          -> Package['clamonacc runtime daemon']
      } else {
        $runtime_daemon_package = 'clamav-daemon'
        $runtime_daemon_user = 'clamav'
        $runtime_daemon_group = 'clamav'

        Package['clamonacc runtime client']
          -> Package['clamonacc runtime daemon']
      }

      package { 'clamonacc runtime client':
        ensure => installed,
        name   => 'clamav',
      }

      package { 'clamonacc runtime daemon':
        ensure => installed,
        name   => $runtime_daemon_package,
      }

      file { [
          '/tmp/clamonacc-runtime-watch',
          '/tmp/clamonacc-runtime-excluded',
          '/tmp/clamonacc-runtime-excluded-refresh',
        ]:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0777',
      }

      file { '/tmp/clamonacc-runtime-db':
        ensure  => directory,
        owner   => $runtime_daemon_user,
        group   => $runtime_daemon_group,
        mode    => '0755',
      }

      file { '/run/clamonacc-runtime':
        ensure  => directory,
        owner   => $runtime_daemon_user,
        group   => $runtime_daemon_group,
        mode    => '0755',
      }

      file { '/tmp/clamonacc-runtime-db/local-test.hdb':
        ensure  => file,
        owner   => $runtime_daemon_user,
        group   => $runtime_daemon_group,
        mode    => '0644',
        content => "44d88612fea8a8f36de82e1278abb02f:68:Eicar-Test-Signature\n",
      }

      file { '/etc/clamonacc-runtime-clamd.conf':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => @("CONFIG")
          DatabaseDirectory /tmp/clamonacc-runtime-db
          LocalSocket /run/clamonacc-runtime/clamd.sock
          Foreground true
          User ${runtime_daemon_user}
          | CONFIG
        notify  => Exec['clamonacc-runtime-systemd-reload'],
      }

      file { '/etc/systemd/system/clamonacc-runtime-clamd.service':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => @("UNIT")
          [Unit]
          Description=clamonacc runtime acceptance clamd
          [Service]
          Type=simple
          ExecStart=/usr/sbin/clamd --config-file=/etc/clamonacc-runtime-clamd.conf
          | UNIT
        notify  => Exec['clamonacc-runtime-systemd-reload'],
      }

      exec { 'clamonacc-runtime-systemd-reload':
        command     => '/usr/bin/systemctl daemon-reload',
        refreshonly => true,
        before      => Service['clamonacc-runtime-clamd'],
      }

      service { 'clamonacc-runtime-clamd':
        ensure     => running,
        enable     => false,
        hasrestart => true,
        hasstatus  => true,
      }

      class { 'clamav::clamonacc':
        binary_path         => '/usr/sbin/clamonacc',
        config_path         => '/etc/clamonacc-runtime.conf',
        service_name        => 'clamonacc-runtime',
        service_enable      => false,
        manage_service_unit => true,
        service_unit_path   => '/etc/systemd/system/clamonacc-runtime.service',
        daemon_service_name => 'clamonacc-runtime-clamd',
        daemon_username     => $runtime_daemon_user,
        local_socket        => '/run/clamonacc-runtime/clamd.sock',
        include_paths       => ['/tmp/clamonacc-runtime-watch'],
        exclude_paths       => [#{rendered_excludes}],
        exclude_usernames   => [$runtime_daemon_user],
        manage_quarantine   => true,
        quarantine_path     => '/tmp/clamonacc-runtime-quarantine',
        quarantine_owner    => 'root',
        quarantine_group    => 'root',
        quarantine_mode     => '0700',
      }

      Service['clamonacc-runtime-clamd'] -> Class['clamav::clamonacc']
    PUPPET
  end

  def wait_for(command)
    run_shell("for attempt in $(seq 1 20); do #{command} && exit 0; sleep 1; done; exit 1")
  end

  def validate_runtime_manifest(manifest)
    encoded = Base64.strict_encode64(manifest)
    run_shell("printf '%s' '#{encoded}' | base64 -d > /tmp/clamonacc-runtime.pp")
    result = run_shell('puppet parser validate /tmp/clamonacc-runtime.pp 2>&1', expect_failures: true)
    expect(result.exit_code).to eq(0), result.stdout
  end

  before(:each) do
    skip 'real clamonacc coverage runs on Ubuntu 24.04, Debian 12, and AlmaLinux 9' unless supported_target?
  end

  after(:all) do
    next unless supported_target?

    run_shell('systemctl disable --now clamonacc-runtime clamonacc-runtime-clamd', expect_failures: true)
    run_shell('rm -f /etc/systemd/system/clamonacc-runtime.service /etc/systemd/system/clamonacc-runtime-clamd.service')
    run_shell('rm -f /etc/clamonacc-runtime.conf /etc/clamonacc-runtime-clamd.conf')
    run_shell('rm -rf /tmp/clamonacc-runtime-watch /tmp/clamonacc-runtime-excluded')
    run_shell('rm -rf /tmp/clamonacc-runtime-excluded-refresh /tmp/clamonacc-runtime-quarantine')
    run_shell('rm -rf /tmp/clamonacc-runtime-db /run/clamonacc-runtime')
    run_shell('systemctl daemon-reload')
  end

  it 'detects, excludes, quarantines, refreshes, and converges with real fanotify' do
    manifest = runtime_manifest
    validate_runtime_manifest(manifest)
    apply_manifest(manifest, catch_failures: true)

    expect(run_shell('test -x /usr/sbin/clamonacc').exit_code).to eq(0)
    expect(run_shell('systemctl is-active clamonacc-runtime-clamd').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-active clamonacc-runtime').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamonacc-runtime', expect_failures: true).stdout.strip).to eq('disabled')
    expect(
      wait_for("journalctl -u clamonacc-runtime --no-pager | grep -F \"watching '/tmp/clamonacc-runtime-watch'\""),
    ).to have_attributes(exit_code: 0)

    run_shell("printf '%s' '#{eicar_content}' > /tmp/clamonacc-runtime-excluded/eicar-excluded.com")
    sleep 1
    expect(run_shell('test -f /tmp/clamonacc-runtime-excluded/eicar-excluded.com').exit_code).to eq(0)
    expect(run_shell('test ! -f /tmp/clamonacc-runtime-quarantine/eicar-excluded.com').exit_code).to eq(0)

    daemon_user = run_shell("awk '/^User / { print $2 }' /etc/clamonacc-runtime-clamd.conf").stdout.strip
    run_shell("runuser -u '#{daemon_user}' -- sh -c \"printf '%s' '#{eicar_content}' > /tmp/clamonacc-runtime-watch/eicar-user-excluded.com\"")
    sleep 1
    expect(run_shell('test -f /tmp/clamonacc-runtime-watch/eicar-user-excluded.com').exit_code).to eq(0)
    expect(run_shell('test ! -f /tmp/clamonacc-runtime-quarantine/eicar-user-excluded.com').exit_code).to eq(0)

    run_shell("printf '%s' '#{eicar_content}' > /tmp/clamonacc-runtime-watch/eicar-detected.com")
    expect(wait_for('test -f /tmp/clamonacc-runtime-quarantine/eicar-detected.com')).to have_attributes(exit_code: 0)
    expect(run_shell('test ! -f /tmp/clamonacc-runtime-watch/eicar-detected.com').exit_code).to eq(0)
    expect(
      run_shell("journalctl -u clamonacc-runtime --no-pager | grep -E 'Eicar-Test-Signature(\\.UNOFFICIAL)? FOUND'").exit_code,
    ).to eq(0)
    expect(
      run_shell("journalctl -u clamonacc-runtime --no-pager | grep -F \"moved to '/tmp/clamonacc-runtime-quarantine/eicar-detected.com'\"").exit_code,
    ).to eq(0)

    first_pid = run_shell('systemctl show clamonacc-runtime -p MainPID --value').stdout.strip
    apply_manifest(runtime_manifest('/tmp/clamonacc-runtime-excluded-refresh'), catch_failures: true)
    second_pid = run_shell('systemctl show clamonacc-runtime -p MainPID --value').stdout.strip

    expect(second_pid).not_to eq(first_pid)
    expect(run_shell("grep -Fx 'OnAccessExcludePath /tmp/clamonacc-runtime-excluded-refresh' /etc/clamonacc-runtime.conf").exit_code).to eq(0)
    expect(run_shell('systemctl is-active clamonacc-runtime').stdout.strip).to eq('active')
    expect(run_shell("stat -c '%U:%G %a' /tmp/clamonacc-runtime-quarantine").stdout.strip).to eq('root:root 700')
    expect(
      acceptance_evidence(
        'clamonacc_runtime',
        '/usr/sbin/clamonacc --config-file=/etc/clamonacc-runtime.conf --version 2>&1',
      ),
    ).to match(%r{ClamAV \d+[.]\d+[.]\d+})

    idempotent_apply(runtime_manifest('/tmp/clamonacc-runtime-excluded-refresh'))
  end
end
