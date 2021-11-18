# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "bundler/setup"
require "all_futures"
require "minitest/autorun"
require "minitest/spec"

# Configure Kredis to allow for testing without Redis in order to avoid exception:
# NoMethodError: undefined method `config_for' for nil:NilClass
Kredis.configurator = Class.new { def config_for(name); {db: "1"}; end }.new
