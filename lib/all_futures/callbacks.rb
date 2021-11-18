# frozen_string_literal: true

require "active_support/callbacks"

module Callbacks
  extend ActiveSupport::Concern

  CALLBACKS = [:before_save, :after_save, :before_update, :after_update, :before_destroy, :after_destroy, :after_find]

  def self.prepended(base)
    base.include(ActiveSupport::Callbacks)

    base.define_callbacks(:save, :update, :destroy, :find, skip_after_callbacks_if_terminated: true) unless base.respond_to?(:_perform_callbacks) && base._perform_callbacks.present?

    class << base
      prepend ClassMethods
    end
  end

  def save(*args)
    if respond_to?(:run_callbacks)
      run_callbacks __callee__ do
        super(*args)
      end
    else
      super(*args)
    end
  end
  alias_method :update, :save
  alias_method :destroy, :save
  alias_method :find, :save

  module ClassMethods
    def method_missing(name, *filters, &blk)
      if CALLBACKS.include? name
        callback = name.to_s.split("_")
        set_callback(callback[1].to_sym, callback[0].to_sym, *filters, &blk)
      end
      super
    end

    def respond_to_missing?(name, include_all)
      CALLBACKS.include?(name) || super
    end
  end
end
