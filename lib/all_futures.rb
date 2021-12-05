# frozen_string_literal: true

require "active_entity/railtie"
require "active_record/errors"
require "active_record/integration"
require "active_record/validations"
require "kredis"
require "all_futures/version"
require "all_futures/callbacks"
require "all_futures/versioning"
require "all_futures/dirty"
require "all_futures/attributes"
require "all_futures/persist"
require "all_futures/timestamp"
require "all_futures/base"

require "all_futures/railtie" if defined?(Rails::Railtie)
