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
end
