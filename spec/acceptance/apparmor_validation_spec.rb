# frozen_string_literal: true

require 'spec_helper_acceptance'

# Opt in only on a disposable Ubuntu VM with policy administration and kernel
# journal access. Missing enforcement is a failure after opting in, never a pass.
describe 'ClamAV configuration validation with enforced Ubuntu AppArmor' do
  let(:validators) do
    {
      'freshclam' => { binary: '/usr/bin/freshclam', profile: 'usr.bin.freshclam', status: 2 },
      'clamd' => { binary: '/usr/sbin/clamd', profile: 'usr.sbin.clamd', status: 1 },
    }
  end
  let(:manifest) do
    <<~PUPPET
      class { 'clamav':
        manage_repo => false,
        manage_clamd => true,
        manage_freshclam => true,
        manage_apparmor => true,
        clamd_default_options => {
          'DatabaseDirectory' => '/var/lib/clamav',
          'LocalSocket' => '/run/clamav/clamd.ctl',
          'User' => 'clamav',
          'LogTime' => true,
        },
        freshclam_default_options => {
          'DatabaseOwner' => 'clamav',
          'DatabaseDirectory' => '/var/lib/clamav',
          'DatabaseMirror' => 'database.clamav.net',
          'Checks' => 2,
        },
      }
    PUPPET
  end

  before(:each) do
    skip 'requires CLAMAV_APPARMOR_ACCEPTANCE=1 and a disposable enforcing Ubuntu VM' unless ENV['CLAMAV_APPARMOR_ACCEPTANCE'] == '1'
  end

  it 'validates real siblings for both configs on the first apply and recovers stale policy' do
    expect(run_shell('facter os.release.full').stdout).to start_with('24.04')
    run_shell('apt-get update && apt-get install -y apparmor clamav-daemon clamav-freshclam')
    run_shell('systemctl stop clamav-daemon clamav-freshclam clamav-daemon.socket')
    acceptance_evidence('apparmor_package_versions', 'dpkg-query -W apparmor clamav-daemon clamav-freshclam')
    acceptance_evidence('apparmor_puppet_version', 'puppet --version')
    run_shell("printf '%s\\n' '44d88612fea8a8f36de82e1278abb02f:68:Eicar-Test-Signature' > /var/lib/clamav/local-test.hdb")
    run_shell('chown clamav:clamav /var/lib/clamav/local-test.hdb')
    run_shell('chmod 0644 /var/lib/clamav/local-test.hdb')
    parent_digests = {}

    validators.each do |name, settings|
      parent = "/etc/apparmor.d/#{settings[:profile]}"
      config = "/etc/clamav/#{name}.conf"
      parent_digests[name] = run_shell("sha256sum #{parent}").stdout
      # This test owns the disposable target's local files, never the parent.
      run_shell("printf '' > /etc/apparmor.d/local/#{settings[:profile]}")
      run_shell("apparmor_parser -r -T -W #{parent}")
      expect(run_shell('cat /sys/kernel/security/apparmor/profiles').stdout).to include("#{settings[:binary]} (enforce)")
      run_shell("printf 'LogSyslog false\\n' > #{config}")
      # Prove that a failure on the copied file is policy, not invalid syntax.
      run_shell("#{settings[:binary]} --config-file #{config} --version")
      run_shell("cp #{config} #{config}.puppet-test")
      denied = run_shell("#{settings[:binary]} --config-file #{config}.puppet-test --version", expect_failures: true)
      expect(denied.exit_code).to eq(settings[:status])
      expect(run_shell('journalctl -k --no-pager -n 200').stdout)
        .to match(%r{apparmor="DENIED".*profile="#{settings[:binary]}".*#{name}\.conf.puppet-test})
    end
    # Simulate upgrade from the previous module-owned helper.
    run_shell("printf '# old helper\\n' > /usr/local/sbin/clamav-freshclam-apparmor")
    cursor = run_shell('journalctl -k -n 0 --show-cursor').stdout[%r{-- cursor: (.+)}, 1]
    expect(cursor).not_to be_nil
    apply_manifest(manifest, catch_failures: true)
    expect(run_shell("grep -Fx 'Checks 2' /etc/clamav/freshclam.conf").exit_code).to eq(0)
    expect(run_shell("grep -Fx 'LogTime true' /etc/clamav/clamd.conf").exit_code).to eq(0)
    run_shell('test ! -e /usr/local/sbin/clamav-freshclam-apparmor')

    validators.each do |name, settings|
      config = "/etc/clamav/#{name}.conf"
      run_shell("cp #{config} #{config}.puppet-test")
      run_shell("#{settings[:binary]} --config-file #{config}.puppet-test --version")
      expect(run_shell('cat /sys/kernel/security/apparmor/profiles').stdout).to include("#{settings[:binary]} (enforce)")
      expect(run_shell("sha256sum /etc/apparmor.d/#{settings[:profile]}").stdout).to eq(parent_digests[name])
    end
    expect(run_shell("journalctl -k --after-cursor='#{cursor}' --no-pager").stdout)
      .not_to match(%r{apparmor="DENIED".*profile="/usr/(bin/freshclam|sbin/clamd)"})
    ['clamav-daemon', 'clamav-freshclam'].each do |service|
      expect(run_shell("systemctl is-active #{service}").stdout.strip).to eq('active')
    end
    apply_manifest(manifest, catch_changes: true)

    { 'freshclam' => "'Checks' => 2", 'clamd' => "'LogTime' => true" }.each do |name, setting|
      config = "/etc/clamav/#{name}.conf"
      digest = run_shell("sha256sum #{config}").stdout
      apply_manifest(manifest.sub(setting, "'DefinitelyInvalidDirective' => true"), expect_failures: true)
      expect(run_shell("sha256sum #{config}").stdout).to eq(digest)
    end

    # Revert only loaded candidate allowances while leaving managed files
    # correct. Each readiness guard must recover without a File refresh.
    validators.each_value do |settings|
      local = "/etc/apparmor.d/local/#{settings[:profile]}"
      run_shell("cp #{local} #{local}.acceptance-backup")
      begin
        run_shell("printf '' > #{local}")
        run_shell("apparmor_parser -r -T -W /etc/apparmor.d/#{settings[:profile]}")
      ensure
        run_shell("mv #{local}.acceptance-backup #{local}")
      end
    end
    changed_manifest = manifest.sub("'Checks' => 2", "'Checks' => 3").sub("'LogTime' => true", "'LogTime' => false")
    apply_manifest(changed_manifest, catch_failures: true)
    expect(run_shell("grep -Fx 'Checks 3' /etc/clamav/freshclam.conf").exit_code).to eq(0)
    expect(run_shell("grep -Fx 'LogTime false' /etc/clamav/clamd.conf").exit_code).to eq(0)
    apply_manifest(changed_manifest, catch_changes: true)
    validators.each_key { |name| run_shell("rm -f /etc/clamav/#{name}.conf.puppet-test") }
  end
end
