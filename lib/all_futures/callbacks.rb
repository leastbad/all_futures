# frozen_string_literal: true

require "active_support/callbacks"

module Callbacks
  extend ActiveSupport::Concern

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
    def around_save(*filters, &blk)
      set_callback(:save, :around, *filters, &blk)
    end

    def before_save(*filters, &blk)
      set_callback(:save, :before, *filters, &blk)
    end

    def after_save(*filters, &blk)
      set_callback(:save, :after, *filters, &blk)
    end

    def around_update(*filters, &blk)
      set_callback(:update, :around, *filters, &blk)
    end

    def before_update(*filters, &blk)
      set_callback(:update, :before, *filters, &blk)
    end

    def after_update(*filters, &blk)
      set_callback(:update, :after, *filters, &blk)
    end

    def around_destroy(*filters, &blk)
      set_callback(:destroy, :around, *filters, &blk)
    end

    def before_destroy(*filters, &blk)
      set_callback(:destroy, :before, *filters, &blk)
    end

    def after_destroy(*filters, &blk)
      set_callback(:destroy, :after, *filters, &blk)
    end

    def after_find(*filters, &blk)
      set_callback(:find, :after, *filters, &blk)
    end
  end
end