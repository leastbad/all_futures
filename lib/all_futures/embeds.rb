# frozen_string_literal: true

module AllFutures
  module Embeds
    extend ActiveSupport::Concern

    class_methods do
      def embedded_in(name, **options)
        autosave = options.delete(:autosave)
        dependent = options.delete(:dependent)
        foreign_key = options.delete(:foreign_key)
        embeds = super
        embeds[name.to_s].options[:autosave] = autosave
        embeds[name.to_s].options[:dependent] = dependent
        embeds[name.to_s].options[:foreign_key] = foreign_key || model_name.singular + "_id"
      end

      def embeds_one(name, **options)
        autosave = options.delete(:autosave)
        dependent = options.delete(:dependent)
        foreign_key = options.delete(:foreign_key)
        embeds = super
        embeds[name.to_s].options[:autosave] = autosave
        embeds[name.to_s].options[:dependent] = dependent
        embeds[name.to_s].options[:foreign_key] = foreign_key || model_name.singular + "_id"
      end

      def embeds_many(name, **options)
        autosave = options.delete(:autosave)
        dependent = options.delete(:dependent)
        foreign_key = options.delete(:foreign_key)
        embeds = super
        embeds[name.to_s].options[:autosave] = autosave
        embeds[name.to_s].options[:dependent] = dependent
        embeds[name.to_s].options[:foreign_key] = foreign_key || model_name.singular + "_id"
      end
    end
  end
end
