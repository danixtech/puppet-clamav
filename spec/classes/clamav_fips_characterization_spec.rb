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

  context 'with module defaults' do
    let(:params) { { manage_clamd: true, manage_freshclam: true } }

    it 'does not impose FIPS hash limits globally' do
      is_expected.to contain_file('clamd.conf')
        .without_content(%r{^FIPSCryptoHashLimits\s}m)
      is_expected.to contain_file('freshclam.conf')
        .without_content(%r{^FIPSCryptoHashLimits\s}m)
    end
  end

  context 'with explicit ClamAV 1.5 caller policy' do
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        clamd_options: { 'FIPSCryptoHashLimits' => true },
        freshclam_options: { 'FIPSCryptoHashLimits' => true },
      }
    end

    it 'renders the caller policy for both ClamAV components' do
      is_expected.to contain_file('clamd.conf')
        .with_content(%r{^FIPSCryptoHashLimits true$}m)
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^FIPSCryptoHashLimits true$}m)
    end
  end

  context 'with explicit compatibility opt-out' do
    let(:params) do
      {
        manage_clamd: true,
        manage_freshclam: true,
        clamd_options: { 'FIPSCryptoHashLimits' => false },
        freshclam_options: { 'FIPSCryptoHashLimits' => false },
      }
    end

    it 'preserves an explicit false value' do
      is_expected.to contain_file('clamd.conf')
        .with_content(%r{^FIPSCryptoHashLimits false$}m)
      is_expected.to contain_file('freshclam.conf')
        .with_content(%r{^FIPSCryptoHashLimits false$}m)
    end
  end
end
