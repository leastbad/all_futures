# frozen_string_literal: true

module AllFutures
  class Base < ActiveEntity::Base
    prepend ::AllFutures::Callbacks
    include ::ActiveModel::Conversion
    include ::AllFutures::Persist
    include ::AllFutures::Dirty

    def initialize(attributes = {})
      # `active_entity/inheritance.rb:49` defaults `attributes` to `nil`, and our method signature has no effect
      attributes ||= {}

      # in order to avoid FrozenError: can't modify id when persisted in `id=`
      attributes_for_super = attributes.key?(:id) ? attributes.except(:id) : attributes
      super(attributes_for_super) do
        @id = attributes&.fetch(:id, nil) || SecureRandom.uuid
        @redis_key = "#{self.class.name}:#{@id}"
        @new_record = !Kredis.redis.exists?(@redis_key)

        @destroyed = false
        @previously_new_record = false

        @attributes.keys.each do |attr|
          define_singleton_method("saved_change_to_#{attr}?") { saved_change_to_attribute?(attr) }
          define_singleton_method("saved_change_to_#{attr}") { saved_change_to_attribute?(attr) ? [attribute_previously_was(attr), attribute_was(attr)] : nil }
          define_singleton_method("#{attr}_will_change?") { attribute_will_change?(attr) }
        end
      end
    end

    def self.create(attributes = {})
      new(attributes).tap { |record| record.save }
    end

    def self.find(id)
      raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} without an ID") unless id

      json = Kredis.json("#{name}:#{id}").value
      raise ActiveRecord::RecordNotFound.new("Couldn't find #{name} with ID #{id}") unless json

      new json.merge(id: id)
    end

    def self.readonly_attribute?(name)
      _attr_readonly.include?(name.to_s)
    end

    def id
      new_record? ? nil : @id
    end

    def id=(value)
      raise FrozenError.new("can't modify id when persisted") unless new_record?
      @id = value.to_s
    end

    private

    def _raise_unknown_attribute_error(attribute)
      raise ActiveModel::UnknownAttributeError.new(self, attribute)
    end
  end
end
