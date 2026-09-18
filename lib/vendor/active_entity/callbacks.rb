# frozen_string_literal: true

module ActiveEntity
  module Callbacks
    extend ActiveSupport::Concern

    CALLBACKS = [
      :after_initialize, :before_validation, :after_validation
    ]

    module ClassMethods # :nodoc:
      include ActiveModel::Callbacks
    end

    included do
      include ActiveModel::Validations::Callbacks

      define_model_callbacks :initialize, only: :after
    end
  end
end
