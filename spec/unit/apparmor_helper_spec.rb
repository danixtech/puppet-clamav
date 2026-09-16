# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'open3'

# Platform paths in a private copy are replaced with test fixtures. These are
# subprocess failure/cleanup tests, not evidence of kernel AppArmor enforcement.
describe 'ClamAV AppArmor helper' do
  ['freshclam', 'clamd'].each do |name|
    context "for #{name}" do
      let(:validator) { name }
      let(:profile_name) { (name == 'freshclam') ? 'usr.bin.freshclam' : 'usr.sbin.clamd' }
      let(:directory) { Dir.mktmpdir('clamav-apparmor') }
      let(:config) { "#{directory}/#{validator} config.conf" }
      let(:profile) { "#{directory}/policy/#{profile_name}" }
      let(:pending) { "#{directory}/policy/local/.clamav-#{validator}-reload-pending" }
      let(:kernel_profiles) { "#{directory}/kernel-profiles" }
      let(:binary) { "#{directory}/#{validator}" }
      let(:script) { "#{directory}/helper" }
      let(:parser_log) { "#{directory}/parser.log" }

      after(:each) { FileUtils.remove_entry(directory) }

      before(:each) do
        FileUtils.mkdir_p("#{directory}/policy/local")
        File.write(config, 'live config must stay untouched')
        File.write(profile, "  #include <local/#{profile_name}>\n")
        File.write(kernel_profiles, "#{binary} (enforce)\n")
        File.write("#{directory}/stale", '')
        File.write("#{directory}/parser", <<~SH)
          #!/bin/sh
          [ ! -f '#{directory}/fail-parser' ] || exit 42
          printf '%s\\n' "$*" >> '#{parser_log}'
          printf '%s\\n' '#{binary} (enforce)' > '#{kernel_profiles}'
          rm -f '#{directory}/stale'
        SH
        File.write(binary, <<~SH)
          #!/bin/sh
          [ ! -f '#{directory}/stale' ] || exit 2
          [ "$1" = --config-file ] || exit 3
          [ "$3" = --version ] || exit 3
          [ "$(cat "$2")" = 'LogSyslog false' ] || exit 4
        SH
        File.chmod(0o755, "#{directory}/parser", binary)
        content = File.read(File.expand_path('../../files/apparmor', __dir__))
                      .gsub('/etc/apparmor.d', "#{directory}/policy")
                      .sub('/sys/kernel/security/apparmor/profiles', kernel_profiles)
                      .sub('/usr/sbin/apparmor_parser', "#{directory}/parser")
                      .sub('/usr/bin/freshclam', "#{directory}/freshclam")
                      .sub('/usr/sbin/clamd', "#{directory}/clamd")
        File.write(script, content)
      end

      def invoke(operation, target = validator)
        Open3.capture3('/bin/sh', script, operation, target, config)
      end

      it 'repairs stale candidate permissions, cleans probes, and never changes live config' do
        expect(invoke('check').last.exitstatus).to eq(2)
        expect(Dir.glob("#{config}*")).to eq([config])
        expect(invoke('reload').last).to be_success
        expect(invoke('check').last).to be_success
        expect(File.read(parser_log)).to eq("--replace --skip-read-cache --write-cache #{profile}\n")
        expect(File.read(config)).to eq('live config must stay untouched')
        expect(Dir.glob("#{config}*")).to eq([config])
        expect(File).not_to exist(pending)
      end

      it 'detects an unloaded profile even when the unconfined candidate read would succeed' do
        File.unlink("#{directory}/stale")
        File.write(kernel_profiles, '/unrelated/binary (enforce)')
        expect(invoke('check').last).not_to be_success
        expect(invoke('reload').last).to be_success
        expect(invoke('check').last).to be_success
      end

      it 'checks readiness in complain mode without changing the selected mode' do
        File.unlink("#{directory}/stale")
        File.write(kernel_profiles, "#{binary} (complain)\n")
        expect(invoke('check').last).to be_success
        expect(File).not_to exist(parser_log)
      end

      it 'retries a failed refresh even if old policy still allows candidate reads' do
        File.write("#{directory}/fail-parser", '')
        expect(invoke('reload').last.exitstatus).to eq(42)
        expect(File).to exist(pending)
        File.unlink("#{directory}/stale")
        expect(invoke('check').last).not_to be_success
        File.unlink("#{directory}/fail-parser")
        expect(invoke('reload').last).to be_success
        expect(File).not_to exist(pending)
      end

      it 'fails before loading if the correct local include is absent' do
        File.write(profile, '#include <local/unrelated>')
        _, error, status = invoke('reload')
        expect(status).not_to be_success
        expect(error).to include('must include')
        expect(File).not_to exist(parser_log)
        expect(Dir.glob("#{config}*")).to eq([config])
      end

      it 'accepts the optional local include syntax' do
        File.write(profile, "include if exists <local/#{profile_name}>\n")
        expect(invoke('reload').last).to be_success
      end

      it 'does not confuse the other validator retry flag with this profile' do
        other = (validator == 'freshclam') ? 'clamd' : 'freshclam'
        other_pending = "#{directory}/policy/local/.clamav-#{other}-reload-pending"
        File.write(other_pending, '')
        expect(invoke('reload').last).to be_success
        expect(invoke('check').last).to be_success
        expect(File).to exist(other_pending)
      end

      it 'refuses unknown validators before touching policy' do
        expect(invoke('reload', 'clamav-milter').last.exitstatus).to eq(2)
        expect(File).not_to exist(parser_log)
      end
    end
  end
end
