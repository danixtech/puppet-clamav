# frozen_string_literal: true

require 'puppet_litmus'

module ClamavAcceptanceHelpers
  EVIDENCE_PREFIX = 'CLAMAV_ACCEPTANCE_EVIDENCE'

  def acceptance_evidence(key, command, expect_failures: false)
    value = run_shell(command, expect_failures: expect_failures).stdout.strip.gsub(%r{\s+}, ' ')
    puts "#{EVIDENCE_PREFIX} #{key}=#{value}"
    value
  end
end

RSpec.configure do |config|
  config.include ClamavAcceptanceHelpers
end

PuppetLitmus.configure!
