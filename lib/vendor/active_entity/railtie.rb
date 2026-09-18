# frozen_string_literal: true

require "active_entity"
require "rails"
require "active_support/core_ext/object/try"
require "active_model/railtie"

# For now, action_controller must always be present with
# Rails, so let's make sure that it gets required before
# here. This is needed for correctly setting up the middleware.
# In the future, this might become an optional require.
require "action_controller/railtie"

module ActiveEntity
  # = Active Entity Railtie
  class Railtie < Rails::Railtie # :nodoc:
    config.active_entity = ActiveSupport::OrderedOptions.new

    config.eager_load_namespaces << ActiveEntity

    # When loading console, force ActiveEntity::Base to be loaded
    # to avoid cross references when loading a constant for the
    # first time. Also, make it output to STDERR.
    console do |_app|
      require "active_entity/base"
      unless ActiveSupport::Logger.logger_outputs_to?(Rails.logger, STDERR, STDOUT)
        console = ActiveSupport::Logger.new(STDERR)
        Rails.logger.extend ActiveSupport::Logger.broadcast console
      end
    end

    runner do
      require "active_entity/base"
    end

    initializer "active_entity.initialize_timezone" do
      ActiveSupport.on_load(:active_entity) do
        self.time_zone_aware_attributes = true
        self.default_timezone = :utc
      end
    end

    initializer "active_entity.logger" do
      ActiveSupport.on_load(:active_entity) { self.logger ||= ::Rails.logger }
    end


    initializer "active_entity.define_attribute_methods" do |app|
      config.after_initialize do
        ActiveSupport.on_load(:active_entity) do
          if app.config.eager_load
            descendants.each do |model|
              model.define_attribute_methods
            end
          end
        end
      end
    end

    initializer "active_entity.set_configs" do |app|
      ActiveSupport.on_load(:active_entity) do
        configs = app.config.active_entity

        configs.each do |k, v|
          send "#{k}=", v
        end
      end
    end

    initializer "active_entity.set_filter_attributes" do
      ActiveSupport.on_load(:active_entity) do
        self.filter_attributes += Rails.application.config.filter_parameters
      end
    end
  end
end
