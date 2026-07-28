# frozen_string_literal: true

require 'spec_helper'

redhat_10_facts = characterized_os_facts.fetch('redhat-8-x86_64')
redhat_10_facts = Marshal.load(Marshal.dump(redhat_10_facts))
redhat_10_facts[:operatingsystemrelease] = '10.0'
redhat_10_facts[:operatingsystemmajrelease] = '10'
redhat_10_facts[:os]['release']['full'] = '10.0'
redhat_10_facts[:os]['release']['major'] = '10'

describe 'clamav', type: :class do
  let(:facts) { redhat_10_facts }

  context 'on EL10 with current Red Hat defaults and external repository management' do
    let(:params) do
      {
        manage_repo: false,
        manage_clamd: true,
        manage_freshclam: true,
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('epel') }

    it 'characterizes package and sysconfig blockers' do
      is_expected.to contain_package('clamd').with_name('clamav-scanner-systemd')
      is_expected.to contain_package('freshclam').with_name('clamav-update')
      is_expected.to contain_file('freshclam_sysconfig').with_path('/etc/sysconfig/freshclam')
    end
  end

  context 'on EL10 with the externally managed EPEL prototype' do
    let(:params) do
      {
        manage_repo: false,
        manage_clamd: true,
        manage_freshclam: true,
        clamd_package: 'clamd',
        freshclam_package: 'clamav-freshclam',
      }
    end

    it { is_expected.to compile.with_all_deps }
    it { is_expected.not_to contain_class('epel') }

    it 'uses package names currently published by EPEL 10' do
      is_expected.to contain_package('clamav').with_name('clamav')
      is_expected.to contain_package('clamd').with_name('clamd')
      is_expected.to contain_package('freshclam').with_name('clamav-freshclam')
    end

    it 'retains the observed EL10 paths and service units' do
      is_expected.to contain_file('clamd.conf').with_path('/etc/clamd.d/scan.conf')
      is_expected.to contain_file('freshclam.conf').with_path('/etc/freshclam.conf')
      is_expected.to contain_service('clamd').with_name('clamd@scan')
      is_expected.to contain_service('freshclam').with_name('clamav-freshclam')
    end
  end
end
