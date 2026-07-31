require 'spec_helper'

describe 'clamav' do
  let(:facts) { formally_supported_os_facts.fetch('ubuntu-24.04-x86_64') }

  context 'with typed freshclam mirror policy' do
    let(:params) do
      {
        manage_freshclam: true,
        freshclam_mirror_policy: {
          'private_mirrors' => ['https://mirror-a.example.test/clamav', 'https://mirror-b.example.test/clamav'],
          'database_mirrors' => ['db.example.test'],
          'http_proxy_server' => 'proxy.example.test',
          'http_proxy_port' => 8080,
          'tls_verify' => true,
        },
      }
    end

    it do
      is_expected.to contain_file('freshclam.conf').with_content(%r{^PrivateMirror https://mirror-a\.example\.test/clamav\nPrivateMirror https://mirror-b\.example\.test/clamav$}m)
      is_expected.to contain_file('freshclam.conf').with_content(%r{^DatabaseMirror db\.example\.test$}m)
      is_expected.to contain_file('freshclam.conf').with_content(%r{^HTTPProxyServer proxy\.example\.test$}m)
      is_expected.to contain_file('freshclam.conf').with_content(%r{^HTTPProxyPort 8080$}m)
      is_expected.to contain_file('freshclam.conf').with_content(%r{^TLSVerify true$}m)
    end
  end

  context 'when raw freshclam options overlap typed policy' do
    let(:params) do
      {
        manage_freshclam: true,
        freshclam_mirror_policy: { 'private_mirrors' => ['https://typed.example.test/clamav'] },
        freshclam_options: { 'PrivateMirror' => ['https://raw.example.test/clamav'] },
      }
    end

    it do
      is_expected.to contain_file('freshclam.conf').with_content(%r{^PrivateMirror https://raw\.example\.test/clamav$}m)
      is_expected.to contain_file('freshclam.conf').without_content(%r{typed\.example\.test})
    end
  end

  context 'with an invalid mirror policy' do
    let(:params) do
      { freshclam_mirror_policy: { 'http_proxy_port' => 0 } }
    end

    it { is_expected.to compile.and_raise_error(%r{freshclam_mirror_policy}) }
  end
end
