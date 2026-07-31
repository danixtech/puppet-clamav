require 'spec_helper'

describe 'clamav policy types' do
  let(:facts) { on_supported_os['debian-12-x86_64'] }

  it 'accepts legacy package ensure values and service states' do
    is_expected.to compile.with_all_deps
  end

  it 'rejects invalid service ensure values at catalog compilation' do
    let(:params) { { clamd_service_ensure: 'enabled' } }

    is_expected.to compile.and_raise_error(%r{clamd_service_ensure})
  end

  it 'rejects malformed package ensure values at catalog compilation' do
    let(:params) { { clamav_version: 'latest?' } }

    is_expected.to compile.and_raise_error(%r{clamav_version})
  end
end
