# frozen_string_literal: true

module AllFutures
  module Versioning
    extend ActiveSupport::Concern

    included do
      # class_attribute :_attr_readonly, instance_accessor: false, default: []
    end

    def disable_versioning!
      @_versioning_enabled = false
    end

    def enable_versioning!
      @_versioning_enabled = true
    end

    def without_versioning
      return unless block_given?

      disable_versioning!
      yield self
      enable_versioning!

      self
    end

    def _versioning_enabled
      @_versioning_enabled
    end
    alias attr_versioning_enabled? _versioning_enabled

    # def readonly_attribute?(name)
    #   self.class.readonly_attribute?(name)
    # end

    # module ClassMethods
    #   # Attributes listed as readonly will be used to create a new record but update operations will
    #   # ignore these fields.
    #   def attr_readonly(*attributes)
    #     self._attr_readonly = Set.new(attributes.map(&:to_s)) + (_attr_readonly || [])
    #   end

    #   # Returns an array of all the attributes that have been specified as readonly.
    #   def readonly_attributes
    #     _attr_readonly
    #   end

    #   def readonly_attribute?(name) # :nodoc:
    #     _attr_readonly.include?(name)
    #   end
    # end
  end
end