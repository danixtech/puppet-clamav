# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamonacc native quarantine foundation' do
  let(:manifest) do
    <<~PUPPET
      if $facts['os']['family'] == 'RedHat' {
        class { 'epel': }
        Class['epel'] -> Package['clamav-quarantine-fixture']
      }

      package { 'clamav-quarantine-fixture':
        ensure => installed,
        name   => 'clamav',
      }

      file { '/usr/local/sbin/clamonacc-quarantine-fixture':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => "#!/bin/sh\\nexit 0\\n",
      }

      Package['clamav-quarantine-fixture']
        -> File['/usr/local/sbin/clamonacc-quarantine-fixture']
        -> class { 'clamav::clamonacc':
          binary_path         => '/usr/local/sbin/clamonacc-quarantine-fixture',
          config_path         => '/etc/clamonacc-quarantine-fixture.conf',
          validate_config     => false,
          service_name        => 'clamonacc-quarantine-fixture',
          service_ensure      => 'stopped',
          service_enable      => false,
          manage_service_unit => true,
          service_unit_path   => '/etc/systemd/system/clamonacc-quarantine-fixture.service',
          daemon_service_name => 'clamd-quarantine-fixture',
          local_socket        => '/run/clamd-quarantine-fixture.sock',
          include_paths       => ['/tmp/clamonacc-quarantine-input'],
          exclude_paths       => ['/tmp/clamonacc-quarantine'],
          manage_quarantine   => true,
          quarantine_path     => '/tmp/clamonacc-quarantine',
          quarantine_owner    => 'root',
          quarantine_group    => 'root',
          quarantine_mode     => '0700',
        }
    PUPPET
  end

  let(:eicar_content) do
    'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
  end

  before(:each) do
    run_shell('mkdir -p /tmp/clamonacc-quarantine-input')
    run_shell('chmod 0777 /tmp/clamonacc-quarantine-input')
    run_shell("printf '%s\\n' '44d88612fea8a8f36de82e1278abb02f:68:Eicar-Test-Signature' > /tmp/clamonacc-quarantine.hdb")
    run_shell('chmod 0644 /tmp/clamonacc-quarantine.hdb')
  end

  after(:all) do
    run_shell('systemctl disable --now clamonacc-quarantine-fixture', expect_failures: true)
    run_shell('rm -f /etc/systemd/system/clamonacc-quarantine-fixture.service')
    run_shell('rm -f /etc/clamonacc-quarantine-fixture.conf /usr/local/sbin/clamonacc-quarantine-fixture')
    run_shell('rm -rf /tmp/clamonacc-quarantine /tmp/clamonacc-quarantine-input')
    run_shell('rm -f /tmp/clamonacc-quarantine.hdb')
    run_shell('systemctl daemon-reload')
  end

  it 'manages restrictive permissions and safely handles names and collisions' do
    idempotent_apply(manifest)

    expect(run_shell("stat -c '%U:%G %a' /tmp/clamonacc-quarantine").stdout.strip).to eq('root:root 700')
    expect(run_shell("grep -F -- '--move=/tmp/clamonacc-quarantine' /etc/systemd/system/clamonacc-quarantine-fixture.service").exit_code).to eq(0)

    unusual_path = '/tmp/clamonacc-quarantine-input/infected ; sample.com'
    2.times do
      run_shell("printf '%s' '#{eicar_content}' > '#{unusual_path}'")
      scan = run_shell(
        "clamscan --database=/tmp/clamonacc-quarantine.hdb --move=/tmp/clamonacc-quarantine --no-summary '#{unusual_path}'",
        expect_failures: true,
      )
      expect(scan.exit_code).to eq(1)
      expect(scan.stdout).to match(%r{Eicar-Test-Signature(?:\.UNOFFICIAL)? FOUND})
      expect(scan.stdout).to include('moved to')
    end

    expect(run_shell("test -f '/tmp/clamonacc-quarantine/infected ; sample.com'").exit_code).to eq(0)
    expect(run_shell("test -f '/tmp/clamonacc-quarantine/infected ; sample.com.001'").exit_code).to eq(0)
  end

  it 'leaves the infected source in place when quarantine is not writable' do
    apply_manifest(manifest, catch_failures: true)
    run_shell('chmod 0500 /tmp/clamonacc-quarantine')
    failure_path = '/tmp/clamonacc-quarantine-input/permission failure.com'
    run_shell("printf '%s' '#{eicar_content}' > '#{failure_path}'")
    run_shell("chmod 0644 '#{failure_path}'")

    scan = run_shell(
      "runuser -u nobody -- clamscan --database=/tmp/clamonacc-quarantine.hdb --move=/tmp/clamonacc-quarantine --no-summary '#{failure_path}'",
      expect_failures: true,
    )

    expect(scan.exit_code).not_to eq(0)
    expect("#{scan.stdout}\n#{scan.stderr}").to match(%r{(?:permission|quarantine|action_setup|unavailable)}i)
    expect(run_shell("test -f '#{failure_path}'").exit_code).to eq(0)
  end
end
