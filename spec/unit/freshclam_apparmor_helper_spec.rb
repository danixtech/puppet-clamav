# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'open3'

# Substitute fixed platform locations in a private copy so failure/retry and
# cleanup can be exercised without loading host policy or needing root.
describe 'Freshclam AppArmor helper' do
  let(:directory) { Dir.mktmpdir('clamav-apparmor') }
  let(:config) { "#{directory}/freshclam config.conf" }
  let(:profile) { "#{directory}/profile" }
  let(:loaded) { "#{directory}/loaded" }
  let(:script) { "#{directory}/helper" }

  after(:each) { FileUtils.remove_entry(directory) }

  before(:each) do
    File.write(config, 'live config must stay untouched')
    File.write(profile, "  #include <local/usr.bin.freshclam>\n")
    File.write("#{directory}/parser", "#!/bin/sh\n[ ! -f '#{directory}/fail-parser' ] || exit 42\ntouch '#{loaded}'\n")
    File.write("#{directory}/freshclam", <<~SH)
      #!/bin/sh
      [ -f '#{loaded}' ] || exit 2
      [ "$1" = --config-file ] || exit 3
      [ "$3" = --version ] || exit 3
      [ "$(cat "$2")" = 'DatabaseOwner root' ] || exit 4
    SH
    File.chmod(0o755, "#{directory}/parser", "#{directory}/freshclam")
    content = File.read(File.expand_path('../../files/freshclam-apparmor', __dir__))
                  .sub('/etc/apparmor.d/usr.bin.freshclam', profile)
                  .sub('/etc/apparmor.d/local/.clamav-freshclam-reload-pending', "#{directory}/pending")
                  .sub('/usr/sbin/apparmor_parser', "#{directory}/parser")
                  .sub('/usr/bin/freshclam', "#{directory}/freshclam")
    File.write(script, content)
  end

  it 'detects stale policy, reloads, and cleans each probe without changing live config' do
    expect(Open3.capture3('/bin/sh', script, 'check', config).last.exitstatus).to eq(2)
    expect(Dir.glob("#{config}*")).to eq([config])
    expect(Open3.capture3('/bin/sh', script, 'reload', config).last).to be_success
    expect(Open3.capture3('/bin/sh', script, 'check', config).last).to be_success
    expect(File.read(config)).to eq('live config must stay untouched')
    expect(Dir.glob("#{config}*")).to eq([config])
  end

  it 'propagates parser failure and permits retry without a file-change event' do
    File.write("#{directory}/fail-parser", '')
    expect(Open3.capture3('/bin/sh', script, 'reload', config).last.exitstatus).to eq(42)
    expect(File).not_to exist(loaded)
    # A previous loaded rule may still allow the candidate, but a failed
    # caller-policy update must be retried regardless of the read probe.
    File.write(loaded, '')
    expect(Open3.capture3('/bin/sh', script, 'check', config).last).not_to be_success
    File.unlink("#{directory}/fail-parser")
    expect(Open3.capture3('/bin/sh', script, 'reload', config).last).to be_success
    expect(File).not_to exist("#{directory}/pending")
  end

  it 'fails before loading when the local include is missing' do
    File.write(profile, '# no local include')
    _, error, status = Open3.capture3('/bin/sh', script, 'reload', config)
    expect(status).not_to be_success
    expect(error).to include('must include')
    expect(File).not_to exist(loaded)
    expect(Dir.glob("#{config}*")).to eq([config])
  end
end
