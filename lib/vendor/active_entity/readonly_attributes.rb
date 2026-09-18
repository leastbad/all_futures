# frozen_string_literal: true

module ActiveEntity
  module ReadonlyAttributes
    extend ActiveSupport::Concern

    included do
      class_attribute :_attr_readonly, instance_accessor: false, default: []
    end

    def disable_attr_readonly!
      @_attr_readonly_enabled = false
    end

    def enable_attr_readonly!
      @_attr_readonly_enabled = true
    end

    def without_attr_readonly
      return unless block_given?

      disable_attr_readonly!
      yield self
      enable_attr_readonly!

      self
    end

    def _attr_readonly_enabled
      @_attr_readonly_enabled
    end
    alias attr_readonly_enabled? _attr_readonly_enabled

    def readonly_attribute?(name)
      self.class.readonly_attribute?(name)
    end

    module ClassMethods
      # Attributes listed as readonly will be used to create a new record but update operations will
      # ignore these fields.
      def attr_readonly(*attributes)
        self._attr_readonly = Set.new(attributes.map(&:to_s)) + (_attr_readonly || [])
      end

      # Returns an array of all the attributes that have been specified as readonly.
      def readonly_attributes
        _attr_readonly
      end

      def readonly_attribute?(name) # :nodoc:
        _attr_readonly.include?(name)
      end
    end
  end
end
