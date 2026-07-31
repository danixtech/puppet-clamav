require 'spec_helper'

describe 'clamav policy types' do
  let(:facts) { on_supported_os['debian-12-x86_64'] }

  it 'accepts legacy package ensure values and service states' do
    is_expected.to compile.with_all_deps
  end

  context 'with an invalid service ensure value' do
    let(:params) { { clamd_service_ensure: 'enabled' } }

    it { is_expected.to compile.and_raise_error(%r{clamd_service_ensure}) }
  end

  context 'with a malformed package ensure value' do
    let(:params) { { clamav_version: 'latest?' } }

    it { is_expected.to compile.and_raise_error(%r{clamav_version}) }
  end
end
