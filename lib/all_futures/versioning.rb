# frozen_string_literal: true

module AllFutures
  module Versioning
    extend ActiveSupport::Concern

    included do
      class_attribute :versioning, instance_accessor: false, default: false
    end

    def current_version
      @_current_version || 0
    end

    def disable_versioning!
      @_versioning_enabled = false
    end

    def enable_versioning!
      @_versioning_enabled = true
    end

    def versions
      @_versions || []
    end

    def without_versioning
      return unless block_given?

      disable_versioning!
      yield self
      enable_versioning!

      self
    end

    def versioning_enabled?
      @_versioning_enabled
    end

    module ClassMethods
      def enable_versioning!
        self.versioning = true
      end
    end
  end
end