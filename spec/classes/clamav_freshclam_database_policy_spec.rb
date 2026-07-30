# frozen_string_literal: true

require 'spec_helper'

describe 'clamav', type: :class do
  let(:facts) do
    {
      os: {
        family: 'Debian',
        name: 'Ubuntu',
        release: { full: '24.04', major: '24.04' },
      },
    }
  end

  context 'with caller mirror and daemon-notification policy' do
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        freshclam_options: {
          'PrivateMirror' => ['mirror-a.example.test', 'mirror-b.example.test'],
          'DatabaseMirror' => 'database.clamav.net',
          'NotifyClamd' => '/etc/clamav/clamd.conf',
        },
      }
    end

    it 'renders repeated private mirrors in caller order' do
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^PrivateMirror mirror-a\.example\.test\nPrivateMirror mirror-b\.example\.test$}m)
    end

    it 'preserves the public fallback mirror and native clamd notification' do
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^DatabaseMirror database\.clamav\.net$}m)
        .with_content(%r{^NotifyClamd /etc/clamav/clamd\.conf$}m)
    end
  end

  context 'with module defaults' do
    let(:params) { { manage_freshclam: true } }

    it 'retains the existing mirror list and does not invent notification policy' do
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^DatabaseMirror db\.local\.clamav\.net\nDatabaseMirror database\.clamav\.net$}m)
        .without_content(%r{^PrivateMirror\s}m)
        .without_content(%r{^NotifyClamd\s}m)
    end
  end
end
