# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "logger" # activesupport < 7.1 relies on concurrent-ruby to load this; concurrent-ruby >= 1.3.5 no longer does
require "bundler/setup"
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
