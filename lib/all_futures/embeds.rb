# frozen_string_literal: true

module AllFutures
  module Embeds
    extend ActiveSupport::Concern

    class_methods do
      def embedded_in(name, **options)
        autosave = options.delete(:autosave)
        dependent = options.delete(:dependent)
        embeds = super(name, **options)
        embeds[name.to_s].options[:autosave] = autosave
        embeds[name.to_s].options[:dependent] = dependent
      end

      def embeds_one(name, **options)
        autosave = options.delete(:autosave)
        dependent = options.delete(:dependent)
        embeds = super(name, **options)
        embeds[name.to_s].options[:autosave] = autosave
        embeds[name.to_s].options[:dependent] = dependent
      end

      def embeds_many(name, **options)
        autosave = options.delete(:autosave)
        dependent = options.delete(:dependent)
        embeds = super(name, **options)
        embeds[name.to_s].options[:autosave] = autosave
        embeds[name.to_s].options[:dependent] = dependent
      end
    end
  end
end
