# frozen_string_literal: true

module AllFutures
  module Persist
    def becomes(klass)
      became = klass.allocate
      became.send :initialize
      became.instance_variable_set "@attributes", attributes
      became.instance_variable_set "@mutations_from_database", nil
      became.instance_variable_set "@changed_attributes", changed_attributes
      became.instance_variable_set "@new_record", new_record?
      became.instance_variable_set "@destroyed", destroyed?
      became.errors.copy! errors
      became
    end

    def decrement(attribute, by = 1)
      increment attribute, -by
    end

    def decrement!(attribute, by = 1)
      increment! attribute, -by
    end

    def delete
      _delete_record if persisted?
      @destroyed = true
      freeze
    end

    def destroy
      _raise_readonly_record_error if readonly?
      delete
    end

    def destroy!
      _raise_readonly_record_error if readonly?
      _raise_record_not_destroyed_error unless _delete_record > 0
      @destroyed = true
      freeze
    end

    def destroyed?
      @destroyed
    end

    def increment(attribute, by = 1)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      self[attribute] ||= 0
      self[attribute] += by
      self
    end

    def increment!(attribute, by = 1)
      increment attribute, by
      save
      self
    end

    def new_record?
      @new_record
    end

    def previously_new_record?
      @previously_new_record
    end

    def persisted?
      !(@new_record || @destroyed)
    end

    def reload
      record = self.class.send(:load, id)
      attributes.each do |key, value|
        self[key] = record["attributes"][key]
      end
      @new_record = false
      @previously_new_record = false
      instance_variable_set "@mutations_from_database", ActiveModel::NullMutationTracker.instance
      self.class.send(:set_previous_attributes, self, record)
    end

    def save
      create_or_update
    rescue ActiveRecord::RecordInvalid
      false
    end

    def save!
      create_or_update || _raise_record_not_saved_error
    end

    def toggle(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      self[attribute] = !public_send("#{attribute}?")
      self
    end

    def toggle!(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      toggle attribute
      update_attribute attribute, self[attribute]
    end

    def update(attrs)
      assign_attributes attrs
      save
    end

    def update!(attrs)
      assign_attributes attrs
      save!
    end

    def update_attribute(attribute, value)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      _raise_readonly_attribute_error(attribute) if attr_readonly_enabled? && readonly_attribute?(attribute) && attribute_will_change?(attribute)
      write_attribute attribute, value
      save
    end

    private

    def create_or_update
      _raise_readonly_record_error if readonly?
      attributes.each_key { |attribute| _raise_readonly_attribute_error(attribute) if attr_readonly_enabled? && readonly_attribute?(attribute) && attribute_will_change?(attribute) }
      return false if destroyed?
      changes_applied
      result = new_record? ? _create_record : _update_record
      result != false
    end

    def _create_record
      _save_record
      @new_record = false
      @previously_new_record = true
      true
    end

    def _delete_record
      Kredis.redis.del(@redis_key)
    end

    def _save_record
      Kredis.json(@redis_key).value = {attributes: attributes, previous_attributes: previous_attributes}
    end

    def _raise_readonly_attribute_error(attribute)
      raise ActiveRecord::ReadOnlyRecord, "#{attribute} is marked as readonly"
    end

    def _raise_readonly_record_error
      raise ActiveRecord::ReadOnlyRecord, "#{self.class} is marked as readonly"
    end

    def _raise_record_not_destroyed_error
      raise ActiveRecord::RecordNotDestroyed, "Failed to destroy the record"
    end

    def _raise_record_not_saved_error
      raise ActiveRecord::RecordNotSaved, "Failed to save the record"
    end

    def _update_record
      _save_record
      @previously_new_record = false
      true
    end
  end
end
