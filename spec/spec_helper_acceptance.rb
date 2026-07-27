# frozen_string_literal: true

require 'puppet_litmus'

module ClamavAcceptanceHelpers
  EVIDENCE_PREFIX = 'CLAMAV_ACCEPTANCE_EVIDENCE'

  def acceptance_evidence(key, command)
    value = run_shell(command).stdout.strip.gsub(%r{\s+}, ' ')
    puts "#{EVIDENCE_PREFIX} #{key}=#{value}"
    value
  end
end

RSpec.configure do |config|
  config.include ClamavAcceptanceHelpers
end

PuppetLitmus.configure!
