# frozen_string_literal: true

require 'spec_helper_acceptance'

# Run only on a disposable Ubuntu VM with AppArmor policy administration and
# kernel journal access. Opting in makes missing enforcement a failure, not a skip.
describe 'Freshclam validation with enforced Ubuntu AppArmor' do
  let(:config) { '/etc/clamav/freshclam.conf' }
  let(:local_profile) { '/etc/apparmor.d/local/usr.bin.freshclam' }
  let(:parent_profile) { '/etc/apparmor.d/usr.bin.freshclam' }
  let(:manifest) do
    <<~PUPPET
      class { 'clamav':
        manage_repo => false,
        manage_clamd => false,
        manage_apparmor => true,
        manage_freshclam => true,
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

  it 'loads policy before the first config change, preserves validation, and recovers stale policy' do
    expect(run_shell('facter os.release.full').stdout).to start_with('24.04')
    run_shell('apt-get update && apt-get install -y apparmor clamav-freshclam')
    run_shell('systemctl stop clamav-freshclam')
    acceptance_evidence('apparmor_package_versions', 'dpkg-query -W apparmor clamav-freshclam')
    acceptance_evidence('apparmor_puppet_version', 'puppet --version')
    parent_digest = run_shell("sha256sum #{parent_profile}").stdout

    # This test owns the disposable target's local fragment, never the parent.
    run_shell("printf '' > #{local_profile}")
    run_shell("apparmor_parser -r -T -W #{parent_profile}")
    expect(run_shell('cat /sys/kernel/security/apparmor/profiles').stdout).to include('/usr/bin/freshclam (enforce)')
    run_shell("printf 'DatabaseOwner clamav\\nDatabaseMirror database.clamav.net\\nChecks 1\\n' > #{config}")
    run_shell("cp #{config} #{config}.puppet-test")
    denied = run_shell("/usr/bin/freshclam --config-file #{config}.puppet-test --version", expect_failures: true)
    expect(denied.exit_code).to eq(2)
    expect(run_shell('journalctl -k --no-pager -n 200').stdout).to match(%r{apparmor="DENIED".*profile="/usr/bin/freshclam".*freshclam.conf.puppet-test})

    cursor = run_shell('journalctl -k -n 0 --show-cursor').stdout[%r{-- cursor: (.+)}, 1]
    expect(cursor).not_to be_nil
    apply_manifest(manifest, catch_failures: true)
    expect(run_shell("grep -Fx 'Checks 2' #{config}").exit_code).to eq(0)
    run_shell("cp #{config} #{config}.puppet-test")
    expect(run_shell("/usr/bin/freshclam --config-file #{config}.puppet-test --version").exit_code).to eq(0)
    expect(run_shell("journalctl -k --after-cursor='#{cursor}' --no-pager").stdout).not_to match(%r{apparmor="DENIED".*profile="/usr/bin/freshclam"})
    expect(run_shell('systemctl is-active clamav-freshclam').stdout.strip).to eq('active')
    expect(run_shell('cat /sys/kernel/security/apparmor/profiles').stdout).to include('/usr/bin/freshclam (enforce)')
    expect(run_shell("sha256sum #{parent_profile}").stdout).to eq(parent_digest)
    apply_manifest(manifest, catch_changes: true)

    digest = run_shell("sha256sum #{config}").stdout
    apply_manifest(manifest.sub("'Checks' => 2", "'DefinitelyInvalidDirective' => true"), expect_failures: true)
    expect(run_shell("sha256sum #{config}").stdout).to eq(digest)

    # Revert kernel policy while leaving the managed file correct. No File
    # refresh is available on the next apply; the readiness guard must recover.
    run_shell("cp #{local_profile} #{local_profile}.acceptance-backup")
    begin
      run_shell("printf '' > #{local_profile}")
      run_shell("apparmor_parser -r -T -W #{parent_profile}")
    ensure
      run_shell("mv #{local_profile}.acceptance-backup #{local_profile}")
    end
    apply_manifest(manifest.sub("'Checks' => 2", "'Checks' => 3"), catch_failures: true)
    expect(run_shell("grep -Fx 'Checks 3' #{config}").exit_code).to eq(0)
    apply_manifest(manifest.sub("'Checks' => 2", "'Checks' => 3"), catch_changes: true)
    run_shell("rm -f #{config}.puppet-test")
  end
end
