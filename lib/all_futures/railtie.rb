# frozen_string_literal: true

class AllFutures::Railtie < ::Rails::Railtie
  initializer "all_futures.attributes" do
    config.after_initialize do
      ActiveModel::Model.include AllFutures::Attributes if defined?(ActiveModel::Model)
    end

    ActiveSupport.on_load(:active_record) do
      include AllFutures::Attributes
    end
  end

  initializer "all_futures.i18n" do
    ActiveSupport.on_load(:i18n) do
      I18n.load_path << File.expand_path("all_futures/locale/en.yml", __dir__)
    end
  end
end
