# frozen_string_literal: true

module ActiveEntity
  # = Active Entity \Validations
  #
  # Active Entity includes the majority of its validations from ActiveModel::Validations
  # all of which accept the <tt>:on</tt> argument to define the context where the
  # validations are active. Active Entity will always supply either the context of
  # <tt>:create</tt> or <tt>:update</tt> dependent on whether the model is a
  # {new_record?}[rdoc-ref:Persistence#new_record?].
  module Validations
    extend ActiveSupport::Concern
    include ActiveModel::Validations

    # Runs all the validations within the specified context. Returns +true+ if
    # no errors are found, +false+ otherwise.
    #
    # Aliased as #validate.
    #
    # If the argument is +false+ (default is +nil+), the context is set to <tt>:create</tt> if
    # {new_record?}[rdoc-ref:Persistence#new_record?] is +true+, and to <tt>:update</tt> if it is not.
    #
    # \Validations with no <tt>:on</tt> option will run no matter the context. \Validations with
    # some <tt>:on</tt> option will only run in the specified context.
    def valid?(context = nil)
      context ||= :default
      output = super(context)
      errors.empty? && output
    end

    alias_method :validate, :valid?

  private

    def perform_validations(options = {})
      options[:validate] == false || valid?(options[:context])
    end
  end
end

require "active_entity/validations/associated"
require "active_entity/validations/presence"
require "active_entity/validations/absence"
require "active_entity/validations/length"
require "active_entity/validations/subset"
require "active_entity/validations/uniqueness_in_embeds"
require "active_entity/validations/uniqueness_on_active_record"
