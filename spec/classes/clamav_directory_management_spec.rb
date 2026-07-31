require 'spec_helper'

describe 'clamav', type: :class do
  let(:facts) { on_supported_os.fetch('debian-12-x86_64') }

  it 'does not manage operational directories by default' do
    is_expected.to compile.with_all_deps
    expect(catalogue.resources.count { |resource| resource.type == 'File' && resource.title.start_with?('clamav managed directory ') }).to eq(0)
  end

  context 'with explicitly managed directories' do
    let(:params) do
      {
        managed_directories: [
          {
            'path' => '/srv/clamav/run',
            'owner' => 'clamav',
            'group' => 'clamav',
            'mode' => '0750',
          },
        ],
      }
    end

    it do
      is_expected.to contain_file('clamav managed directory /srv/clamav/run').with(
        ensure: 'directory',
        path: '/srv/clamav/run',
        owner: 'clamav',
        group: 'clamav',
        mode: '0750',
      )
    end
  end

  context 'with a relative managed directory path' do
    let(:params) { { managed_directories: [{ 'path' => 'relative/path' }] } }

    it { is_expected.to compile.and_raise_error(%r{managed_directories}) }
  end
end
