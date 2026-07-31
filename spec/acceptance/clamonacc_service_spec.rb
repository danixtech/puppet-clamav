# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'clamav::clamonacc service management' do
  let(:foundation_manifest) do
    <<~PUPPET
      file { '/usr/local/sbin/clamonacc-fixture':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => "#!/bin/sh\\nexec /usr/bin/sleep 86400\\n",
      }

      file { '/etc/systemd/system/clamonacc-fixture-daemon.service':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "[Unit]\\nDescription=clamonacc acceptance daemon\\n[Service]\\nType=simple\\nExecStart=/usr/bin/sleep 86400\\n",
        notify  => Exec['clamonacc-fixture-daemon-reload'],
      }

      exec { 'clamonacc-fixture-daemon-reload':
        command     => '/usr/bin/systemctl daemon-reload',
        refreshonly => true,
        before      => Service['clamonacc-fixture-daemon'],
      }

      service { 'clamonacc-fixture-daemon':
        ensure  => running,
        enable  => false,
        require => File['/etc/systemd/system/clamonacc-fixture-daemon.service'],
      }
    PUPPET
  end

  def service_manifest(exclude_path)
    <<~PUPPET
      #{foundation_manifest}

      File['/usr/local/sbin/clamonacc-fixture']
        -> Service['clamonacc-fixture-daemon']
        -> class { 'clamav::clamonacc':
          binary_path         => '/usr/local/sbin/clamonacc-fixture',
          config_path         => '/etc/clamonacc-fixture.conf',
          validate_config     => false,
          service_name        => 'clamonacc-fixture',
          service_enable      => false,
          manage_service_unit => true,
          service_unit_path   => '/etc/systemd/system/clamonacc-fixture.service',
          daemon_service_name => 'clamonacc-fixture-daemon',
          local_socket        => '/run/clamonacc-fixture.sock',
          include_paths       => ['/tmp'],
          exclude_paths       => ['#{exclude_path}'],
        }
    PUPPET
  end

  after(:all) do
    run_shell('systemctl disable --now clamonacc-fixture clamonacc-fixture-daemon', expect_failures: true)
    run_shell('rm -f /etc/systemd/system/clamonacc-fixture.service /etc/systemd/system/clamonacc-fixture-daemon.service')
    run_shell('rm -f /etc/clamonacc-fixture.conf /usr/local/sbin/clamonacc-fixture')
    run_shell('systemctl daemon-reload')
  end

  it 'starts, refreshes, and converges with an optional module-managed unit' do
    apply_manifest(service_manifest('/proc'), catch_failures: true)

    expect(run_shell('systemctl is-active clamonacc-fixture').stdout.strip).to eq('active')
    expect(run_shell('systemctl is-enabled clamonacc-fixture', expect_failures: true).stdout.strip).to eq('disabled')
    expect(run_shell('systemctl show clamonacc-fixture -p Requires --value').stdout).to include('clamonacc-fixture-daemon.service')
    first_pid = run_shell('systemctl show clamonacc-fixture -p MainPID --value').stdout.strip

    apply_manifest(service_manifest('/sys'), catch_failures: true)
    second_pid = run_shell('systemctl show clamonacc-fixture -p MainPID --value').stdout.strip

    expect(second_pid).not_to eq(first_pid)
    expect(run_shell("grep -Fx 'OnAccessExcludePath /sys' /etc/clamonacc-fixture.conf").exit_code).to eq(0)
    idempotent_apply(service_manifest('/sys'))
  end
end
