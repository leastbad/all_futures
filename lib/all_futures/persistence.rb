# frozen_string_literal: true

module AllFutures
  module Persistence
    extend ActiveSupport::Concern

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
      _raise_invalid_attribute_error(attribute) unless attributes.key?(attribute.to_s)
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
      raise AllFutures::RecordNotSaved.new("Can't load model that hasn't been saved") unless persisted?
      record = self.class.send(:load_model, id)
      attributes.each do |key, value|
        self[key] = record["attributes"][key]
      end
      @new_record = false
      @previously_new_record = false
      if versioning_enabled?
        @_current_version = record["current_version"]
        @_versions = record["versions"].transform_keys(&:to_i)
      end
      instance_variable_set "@mutations_from_database", ActiveModel::NullMutationTracker.instance
      instance_variable_set "@updated_at", Time.zone.parse(record["updated_at"])
      self.class.send(:set_previous_attributes, self, record)
      self
    end

    def save
      create_or_update
    rescue AllFutures::RecordInvalid
      false
    end

    def save!
      create_or_update || _raise_record_not_saved_error
    end

    def toggle(attribute)
      _raise_invalid_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      self[attribute] = !public_send("#{attribute}?")
      self
    end

    def toggle!(attribute)
      _raise_invalid_attribute_error(attribute) unless attributes.key?(attribute.to_s)
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
      _raise_invalid_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      _raise_readonly_attribute_error(attribute) if attr_readonly_enabled? && readonly_attribute?(attribute) && attribute_will_change?(attribute)
      write_attribute attribute, value

      touch

      save
    end

    def touch
      @updated_at = Time.current
    end

    private

    def create_or_update
      _raise_readonly_record_error if readonly?
      attributes.each_key { |attribute| _raise_readonly_attribute_error(attribute) if attr_readonly_enabled? && readonly_attribute?(attribute) && attribute_will_change?(attribute) }
      return false if destroyed?

      touch

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
      _reflections.each do |association, reflection|
        case reflection.macro
        when :embeds_many
          fk = model_name.singular + "_id"
          _raise_missing_foreign_key_error(reflection, fk) unless reflection.klass.has_attribute?(fk)
          send(association).each do |record|
            if record.new_record?
              record.send("#{fk}=", @id)
              record.save
            end
            record.destroy if record.marked_for_destruction?
          end
        when :embeds_one
          fk = model_name.singular + "_id"
          _raise_missing_foreign_key_error(reflection, fk) unless reflection.klass.has_attribute?(fk)
          if (record = send(association))
            if record.new_record?
              record.send("#{fk}=", @id)
              record.save
            end
            record.destroy if record.marked_for_destruction?
          end
        when :embedded_in
          if (record = send(association))
            record.save if record.new_record? && send(reflection.klass.model_name.singular + "_id").nil?
          end
        end
      end

      if versioning_enabled?
        if new_record?
          @_current_version = 1
        else
          record = Kredis.json(@redis_key).value
          @_current_version = record["current_version"] + 1
          @_versions = record["versions"].transform_keys(&:to_i)
        end
        @_versions[current_version] = {
          "attributes" => attributes,
          "updated_at" => Time.current
        }
      end

      Kredis.json(@redis_key).value = {
        attributes: attributes,
        created_at: created_at,
        updated_at: touch,
        previous_attributes: previous_attributes,
        current_version: current_version,
        versions: versions
      }
    end

    def _raise_missing_foreign_key_error(reflection, fk)
      raise AllFutures::MissingForeignKeyError, "#{reflection.klass} missing foreign key #{fk}"
    end

    def _raise_readonly_attribute_error(attribute)
      raise AllFutures::ReadOnlyRecord, "#{attribute} is marked as readonly"
    end

    def _raise_readonly_record_error
      raise AllFutures::ReadOnlyRecord, "#{self.class} is marked as readonly"
    end

    def _raise_record_not_destroyed_error
      raise AllFutures::RecordNotDestroyed, "Failed to destroy the record"
    end

    def _raise_record_not_saved_error
      raise AllFutures::RecordNotSaved, "Failed to save the record"
    end

    def _raise_invalid_attribute_error(attribute)
      raise AllFutures::InvalidAttribute.new(self, attribute)
    end

    def _update_record
      _save_record
      @previously_new_record = false
      true
    end

    module ClassMethods
      def create(attributes = {}, &block)
        new(attributes).tap do |record|
          block&.call(record)
          record.save
        end
      end

      def delete_all
        Kredis.redis.del Kredis.redis.keys("#{name}:*")
      end

      def delete_by(attributes = {}, &block)
        Kredis.redis.del where(attributes, &block).map { |record| "#{name}:#{record.id}" }
      end

      def destroy_all
        all.each(&:destroy)
      end

      def destroy_by(attributes = {}, &block)
        where(attributes, &block).each(&:destroy)
      end

      def readonly_attribute?(name)
        _attr_readonly.include?(name.to_s)
      end

      private

      def load_model(id)
        record = Kredis.json("#{name}:#{id}").value
        raise AllFutures::RecordNotFound.new("Couldn't find #{name} with id #{id}") unless record
        record
      end
    end
  end
end
