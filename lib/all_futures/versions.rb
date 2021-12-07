# frozen_string_literal: true

module AllFutures
  class VersionNotFound < StandardError; end

  module Versions
    extend ActiveSupport::Concern

    Version = Struct.new(:attributes, :updated_at) do
      def to_h
        attributes
      end

      def inspect
        attributes
      end
    end

    included do
      class_attribute :versioning, instance_accessor: false, default: false
    end

    def current_version
      @_current_version.nil? ? nil : @_current_version.to_i
    end

    def disable_versioning!
      @_versioning_enabled = false
    end

    def enable_versioning!
      @_versioning_enabled = true
    end

    def version(index)
      _raise_version_not_found(index) unless versions.key?(index)
      Version.new(versions[index]["attributes"], Time.zone.parse(versions[index]["updated_at"]))
    end

    def versions
      @_versions
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

    private

    def _raise_version_not_found(index)
      raise AllFutures::VersionNotFound, "Could not find version #{index}"
    end

    module ClassMethods
      def enable_versioning!
        self.versioning = true
      end

      def load_versions(model, record)
        return if record["versions"].nil?
        model.instance_variable_set "@_current_version", record["current_version"]
        model.instance_variable_set "@_versions", record["versions"].transform_keys(&:to_i)
      end
    end
  end
end
