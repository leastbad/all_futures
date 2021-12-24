# frozen_string_literal: true

module AllFutures
  class ParentModelNotSavedYet < StandardError; end

  module Attributes
    extend ActiveSupport::Concern

    class_methods do
      def has_future(name, klass, **options)
        ivar_symbol = :"@#{name}_all_futures"

        define_method(name) do
          if instance_variable_defined?(ivar_symbol)
            instance_variable_get(ivar_symbol)
          else
            af_key = if options[:key]
              options[:key]
            else
              record_id = try(:id) or raise AllFutures::ParentModelNotSavedYet, "AllFutures requires a unique key. Either save the parent model before accessing #{name}, or pass a custom key."
              "#{self.class.name.tableize.tr("/", ":")}:#{record_id}:#{name}"
            end
            af = klass.exists?(af_key) ? klass.find(af_key) : klass.new(id: af_key)
            instance_variable_set(ivar_symbol, af)
          end
        end
      end
    end
  end
end
