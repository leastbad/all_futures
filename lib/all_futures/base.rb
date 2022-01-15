# frozen_string_literal: true

module AllFutures
  class Base < ActiveEntity::Base
    prepend ::AllFutures::Callbacks
    extend ::ActiveModel::Naming
    extend ::AllFutures::Translation
    include ::AllFutures::Persistence
    include ::AllFutures::Dirty
    include ::AllFutures::Validations
    include ::AllFutures::Presenter
    include ::AllFutures::Versions
    include ::AllFutures::Finder
    include ::ActiveModel::Conversion
    include ::ActiveModel::SecurePassword
    include ::ActiveRecord::Integration
    include ::Kredis::Attributes

    attr_reader :created_at, :updated_at

    def initialize(attributes = {}, &block)
      attributes ||= {}
      attributes = attributes.attributes.transform_keys(&:to_sym) if attributes.is_a?(ActiveRecord::Base)
      attributes_for_super = attributes.key?(:id) ? attributes.except(:id).except(:created_at).except(:updated_at) : attributes

      super(attributes_for_super) do
        @id = attributes&.fetch(:id, nil) || ULID.generate
        @created_at = Time.current
        @updated_at = attributes&.fetch(:updated_at, Time.current)
        @redis_key = "#{self.class.name}:#{@id}"
        @new_record = !self.class.exists?(@id)
        @destroyed = false
        @previously_new_record = false
        @_versioning_enabled = self.class.versioning
        @_versions = {}
        @_current_version = nil
        @_id_set = attributes.key?(:id)

        @attributes.keys.each do |attr|
          define_singleton_method("#{attr}_changed?") { attribute_changed?(attr) }
          define_singleton_method("#{attr}_valid?") { attribute_valid?(attr) }
          define_singleton_method("rollback_#{attr}") { rollback_attribute(attr) }
          define_singleton_method("rollback_#{attr}!") { rollback_attribute!(attr) }
          define_singleton_method("restore_#{attr}") { restore_attribute(attr) }
          define_singleton_method("restore_#{attr}!") { restore_attribute(attr) }
        end

        block&.call(self)
      end
    end

    def id
      !new_record? || @_id_set ? @id.to_s : nil
    end

    def id=(value)
      raise FrozenError.new("can't modify id when persisted") unless new_record?
      @id = value.to_s
      @redis_key = "#{self.class.name}:#{@id}"
      @_id_set = true
    end
  end

  ActiveSupport.run_load_hooks(:all_futures, Base)
end
