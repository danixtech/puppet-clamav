require 'spec_helper'

supported_os = on_supported_os
debian_11_facts = supported_os.fetch('debian-11-x86_64')

describe 'clamav', type: :class do
  let(:facts) { debian_11_facts }

  context 'with user and group explicitly disabled' do
    let(:params) do
      {
        manage_user: true,
        user: false,
        group: false,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_user('clamav') }
    it { is_expected.not_to contain_group('clamav') }
  end

  context 'with freshclam_delay supplied as a string' do
    let(:params) do
      {
        manage_freshclam: true,
        freshclam_delay: 'disabled',
      }
    end

    it { is_expected.to compile.with_all_deps }

    it do
      is_expected.to contain_class('clamav::freshclam')
        .with_freshclam_delay('disabled')
    end
  end
end

describe 'clamav::clamd', type: :class do
  let(:facts) { debian_11_facts }
  let(:pre_condition) { 'include clamav' }
  let(:params) do
    {
      sort_options: false,
      options: {
        'ZLast' => 'first',
        'AFirst' => 'second',
      },
    }
  end

  it { is_expected.to compile.with_all_deps }

  it 'preserves option insertion order when sorting is disabled' do
    is_expected.to contain_file('/etc/clamav/clamd.conf')
      .with_content(%r{ZLast first\nAFirst second}m)
  end
end

describe 'clamav::freshclam', type: :class do
  let(:facts) { debian_11_facts }
  let(:pre_condition) { 'include clamav' }
  let(:params) { { sort_options: false } }

  it { is_expected.to compile.with_all_deps }
end

describe 'clamav::clamav_milter', type: :class do
  let(:facts) { debian_11_facts }
  let(:pre_condition) { 'include clamav' }
  let(:params) { { sort_options: false } }

  it { is_expected.to compile.with_all_deps }
end
