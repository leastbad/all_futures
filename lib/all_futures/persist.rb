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
      _raise_readonly_attribute_error(attribute) if readonly_attribute?(attribute)
      self[attribute] ||= 0
      self[attribute] += by
      self
    end

    def increment!(attribute, by = 1)
      increment attribute, by
      public_send :"clear_#{attribute}_change"
      self
    end

    def new_record?
      @new_record
    end

    def persisted?
      !(@new_record || @destroyed)
    end

    def previously_new_record?
      @previously_new_record
    end

    def reload
      json = Kredis.json("#{self.class.name}:#{@id}").value
      attributes.each do |key, value|
        self[key] = json[key] if json[key] != value
      end
      @new_record = false
      @previously_new_record = false
      clear_changes_information
      self
    end

    def save(**options, &block)
      create_or_update(**options, &block)
    rescue ActiveRecord::RecordInvalid
      false
    end

    def save!(**options, &block)
      create_or_update(**options, &block) || _raise_record_not_saved_error
    end

    def toggle(attribute)
      self[attribute] = !public_send("#{attribute}?")
      self
    end

    def toggle!(attribute)
      toggle(attribute).update_attribute attribute, self[attribute]
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
      _raise_readonly_record_error if readonly?
      _raise_readonly_attribute_error(attribute) if readonly_attribute? attribute
      public_send "#{attribute}=", value
      save # validate: false
    end

    private

    def create_or_update(**)
      _raise_readonly_record_error if readonly?
      attributes.each { |attribute| _raise_readonly_attribute_error(attribute) if readonly_attribute?(attribute) }
      return false if destroyed?
      result = new_record? ? _create_record : _update_record
      yield(self) if block_given?
      changes_applied
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
      Kredis.json(@redis_key).value = attributes
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
