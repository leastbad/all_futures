# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "logger" # activesupport < 7.1 relies on concurrent-ruby to load this; concurrent-ruby >= 1.3.5 no longer does
require "bundler/setup"

require "coverage"
Coverage.start(lines: true)

require "all_futures"
require "minitest/autorun"
require "minitest/spec"
require "active_record"
require "warning"
require "faker"

Time.zone = "UTC"

# Configure Kredis to allow for testing without Redis in order to avoid exception:
# NoMethodError: undefined method `config_for' for nil:NilClass
Kredis.configurator = Class.new {
  def config_for(name)
    {db: "1"}
  end

  # Kredis >= 1.3 checks for config/redis/*.yml via configurator.root
  def root
    Pathname.new(Dir.pwd)
  end
}.new

# suppress Active Entity class eval warnings for test runner
Warning.ignore(:method_redefined)

Minitest.after_run do
  result = Coverage.result
  lib = File.expand_path("../lib", __dir__)
  relevant = result.select { |path, _| path.start_with?(lib) && !path.include?("/vendor/") }
  lines_for = ->(data) { data.is_a?(Hash) ? data[:lines] : data }
  covered = relevant.sum { |_, data| Array(lines_for.call(data)).count { |n| n.is_a?(Integer) && n.positive? } }
  measurable = relevant.sum { |_, data| Array(lines_for.call(data)).count { |n| n.is_a?(Integer) } }
  pct = measurable.zero? ? 0.0 : (covered * 100.0 / measurable)
  puts format("\nCoverage: %.1f%% (%d/%d lines in lib/)", pct, covered, measurable)
end
