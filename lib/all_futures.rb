# frozen_string_literal: true

require "active_entity/railtie"
require "active_record/errors"
require "active_record/integration"
require "kredis"
require "all_futures/attributes"
require "all_futures/callbacks"
require "all_futures/dirty"
require "all_futures/finder"
require "all_futures/persistence"
require "all_futures/presenter"
require "all_futures/translation"
require "all_futures/validations"
require "all_futures/version"
require "all_futures/versions"
require "all_futures/base"

require "all_futures/railtie" if defined?(Rails::Railtie)

ActiveSupport.on_load(:i18n) do
  I18n.load_path << File.expand_path("all_futures/locale/en.yml", __dir__)
end
