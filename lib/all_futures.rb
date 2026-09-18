# frozen_string_literal: true

require "active_entity/railtie"
require "active_record" # for ActiveRecord::Integration (cache keys) and ActiveRecord::Base checks; internals can't be cherry-picked since Rails 7.1
require "kredis"
require "ulid"
require "all_futures/configuration"
require "all_futures/association_index"
require "all_futures/association"
require "all_futures/attributes"
require "all_futures/callbacks"
require "all_futures/dirty"
require "all_futures/embeds"
require "all_futures/errors"
require "all_futures/finder"
require "all_futures/persistence"
require "all_futures/presenter"
require "all_futures/translation"
require "all_futures/validations"
require "all_futures/version"
require "all_futures/versions"
require "all_futures/base"

require "all_futures/railtie" if defined?(Rails::Railtie)
