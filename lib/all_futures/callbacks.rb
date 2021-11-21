# frozen_string_literal: true

require "active_support/callbacks"

module AllFutures
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [:before_save, :after_save, :before_update, :after_update, :before_destroy, :after_destroy]

    def self.prepended(base)
      base.include(ActiveSupport::Callbacks)

      base.define_callbacks(:save, :update, :destroy, skip_after_callbacks_if_terminated: true) unless base.respond_to?(:_perform_callbacks) && base._perform_callbacks.present?

      class << base
        prepend ClassMethods
      end
    end

    def destroy
      perform_operation(__callee__) if @_trigger_destroy_callback
    end
    alias_method :destroy!, :destroy

    def save
      perform_operation(__callee__)
    end
    alias_method :save!, :save

    def update(attrs = {})
      perform_operation(__callee__, attrs) if @_trigger_update_callback
    end
    alias_method :update!, :update

    def perform_operation(operation, *args)
      if respond_to?(:run_callbacks)
        callback = operation.to_s.sub("!", "").to_sym
        run_callbacks callback do
          method(operation).super_method.call(*args)
        end
      else
        method(operation).super_method.call(*args)
      end
    end

    module ClassMethods
      def method_missing(name, *filters, &blk)
        if CALLBACKS.include? name
          callback_context, method_name = name.to_s.split("_")
          set_callback(method_name.to_sym, callback_context.to_sym, *filters, &blk)
        else
          super
        end
      end

      def respond_to_missing?(name, include_all)
        CALLBACKS.include?(name) || super
      end
    end
  end
end
