# frozen_string_literal: true

require 'spec_helper'

describe 'clamav::apparmor' do
  let(:facts) { formally_supported_os_facts.fetch('ubuntu-24.04-x86_64') }
  let(:pre_condition) { "class { 'clamav': manage_freshclam => true }" }
  let(:params) { { freshclam_config: '/etc/clamav/freshclam.conf' } }

  it 'retains the original internal Freshclam parameter as a compatibility alias' do
    is_expected.to compile.with_all_deps
    is_expected.to contain_file('clamav apparmor /etc/apparmor.d/local/usr.bin.freshclam')
  end

  context 'with both old and new Freshclam inputs' do
    let(:params) { super().merge(validation_configs: { 'freshclam' => '/etc/clamav/freshclam.conf' }) }

    it { is_expected.to compile.and_raise_error(%r{Specify either freshclam_config}) }
  end
end
