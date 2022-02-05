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
      _destroy_associations
      @destroyed = true
      freeze
    end

    def destroy
      _raise_readonly_record_error if readonly?
      delete
    end

    def destroy!
      _raise_readonly_record_error if readonly?
      _destroy_associations
      _raise_record_not_destroyed_error if persisted? && _delete_record == 0
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
      instance_variable_set "@marked_for_destruction", false
      instance_variable_set "@destroyed_by_association", nil
      self.class.send(:set_previous_attributes, self, record)
      self
    end

    def save
      _create_or_update
    rescue AllFutures::RecordInvalid
      false
    end

    def save!
      _create_or_update || _raise_record_not_saved_error
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
      @updated_at = Time.current.utc.to_s
    end

    # treat as private

    def _changed_for_autosave?
      new_record? || has_changes_to_save? || marked_for_destruction? || _nested_records_changed_for_autosave?
    end

    def _nested_records_changed_for_autosave?
      @_nested_records_changed_for_autosave_already_called ||= false
      return false if @_nested_records_changed_for_autosave_already_called
      begin
        @_nested_records_changed_for_autosave_already_called = true
        _reflections.values.any? do |reflection|
          if reflection.options[:autosave]
            association = association_instance_get(reflection.name)
            association && Array.wrap(association.target).any?(&:_changed_for_autosave?)
          end
        end
      ensure
        @_nested_records_changed_for_autosave_already_called = false
      end
    end

    private

    def _association_foreign_key_changed?(reflection, record, key)
      record._has_attribute?(reflection.options[:foreign_key]) && record._read_attribute(reflection.options[:foreign_key]) != key
    end

    def _associated_records_to_validate_or_save(association, new_record, autosave)
      if new_record || _custom_validation_context?
        association&.target
      elsif autosave
        association.target.find_all(&:_changed_for_autosave?)
      else
        association.target.find_all(&:new_record?)
      end
    end

    def _association_valid?(reflection, record, index = nil)
      return true if record.destroyed? || (reflection.options[:autosave] && record.marked_for_destruction?)

      context = validation_context if _custom_validation_context?

      unless (valid = record.valid?(context))
        if reflection.options[:autosave]
          record.errors.group_by_attribute.each do |attribute, errors|
            errors.each do |error|
              self.errors.import(error, attribute: "#{reflection.name}.#{attribute}")
            end
          end
        else
          errors.add(reflection.name)
        end
      end
      valid
    end

    def _create_or_update
      _raise_readonly_record_error if readonly?
      attributes.each_key { |attribute| _raise_readonly_attribute_error(attribute) if attr_readonly_enabled? && readonly_attribute?(attribute) && attribute_will_change?(attribute) }
      return false if destroyed?

      touch

      changes_applied

      previously_new_record_before_save = (@new_record_before_save ||= false)
      @new_record_before_save = !previously_new_record_before_save && new_record?

      _reflections.values.select { |reflection| reflection.macro == :embedded_in }.each do |reflection|
        send("_save_embedded_in", reflection)
      end

      result = new_record? ? _create_record : _update_record

      _reflections.values.reject { |reflection| reflection.macro == :embedded_in }.each do |reflection|
        send("_save_#{reflection.macro}", reflection)
      end

      @new_record_before_save = previously_new_record_before_save

      result != false
    end

    def _create_record
      _save_record
      @new_record = false
      @previously_new_record = true
      true
    end

    def _custom_validation_context?
      validation_context && [:create, :update].exclude?(validation_context)
    end

    def _delete_record
      Kredis.redis.del(@redis_key)
    end

    def _destroy_associations
      _reflections.values.each do |reflection|
        if reflection.options[:dependent]
          association = association_instance_get(reflection.name)
          case reflection.options[:dependent]
          when :delete
            Array.wrap(association.target).each(&:delete)
          when :destroy
            Array.wrap(association.target).each do |record|
              record.destroyed_by_association = reflection
              record.destroy
            end
          when :nullify
            raise AllFutures::InvalidDependentOption.new(:nullify) if reflection.macro == :embedded_in
            association.target.each do |record|
              record.update_attribute(reflection.options[:foreign_key], nil) if association.target.persisted?
            end
          when :restrict_with_exception
            raise AllFutures::InvalidDependentOption.new(:restrict_with_exception) if reflection.macro == :embedded_in
            raise AllFutures::DeleteRestrictionError.new(reflection.name) unless association.empty?
          when :restrict_with_error
            raise AllFutures::InvalidDependentOption.new(:restrict_with_error) if reflection.macro == :embedded_in
            unless association.empty?
              record = association.owner.class.human_attribute_name(reflection.name).downcase
              association.owner.errors.add(:base, :"restrict_dependent_destroy.#{reflection.macro}", record: record)
              throw(:abort)
            end
          end
        end
      end
    end

    def _record_changed?(reflection, record, key)
      record.new_record? ||
        _association_foreign_key_changed?(reflection, record, key) ||
        record.will_save_change_to_attribute?(reflection.options[:foreign_key])
    end

    def _save_embeds_many(reflection)
      if (association = association_instance_get(reflection.name))
        _raise_missing_foreign_key_error(reflection) unless reflection.klass.has_attribute?(reflection.options[:foreign_key])
        autosave = reflection.options[:autosave]

        new_record_before_save = @new_record_before_save

        if (records = _associated_records_to_validate_or_save(association, new_record_before_save, autosave))
          if autosave
            records_to_destroy = records.select(&:marked_for_destruction?)
            records_to_destroy.each { |record| association.destroy(record) }
            records -= records_to_destroy
          end

          records.each do |record|
            next if record.destroyed?

            saved = true

            if autosave != false && (new_record_before_save || record.new_record?)
              association.set_inverse_instance(record)

              if autosave
                record._write_attribute(reflection.options[:foreign_key], id)
                saved = record.save
              elsif !reflection.nested?
                record._write_attribute(reflection.options[:foreign_key], id)
                association_saved = record.save

                if reflection.validate?
                  errors.add(reflection.name) unless association_saved
                  saved = association_saved
                end
              end
            elsif autosave
              saved = record.save
            end

            raise(AllFutures::RecordInvalid.new(association.owner)) unless saved
          end
        end
      end
    end

    def _save_embeds_one(reflection)
      association = association_instance_get(reflection.name)
      _raise_missing_foreign_key_error(reflection) unless reflection.klass.has_attribute?(reflection.options[:foreign_key])

      record = association&.target

      if record && !record.destroyed?
        autosave = reflection.options[:autosave]
        if autosave && record.marked_for_destruction?
          record.destroy
        elsif autosave != false
          if (autosave && record._changed_for_autosave?) || _record_changed?(reflection, record, id)
            record._write_attribute(reflection.options[:foreign_key], id)
            association.set_inverse_instance(record)
            record.save
          end
        end
      end
    end

    def _save_embedded_in(reflection)
      association = association_instance_get(reflection.name)
      return unless association&.loaded?

      record = association.target

      if record && !record.destroyed?
        autosave = reflection.options[:autosave]

        if autosave && record.marked_for_destruction?
          record._write_attribute(reflection.options[:foreign_key], nil)
          record.destroy
        elsif autosave != false
          saved = record.save if record.new_record? || (autosave && record.changed_for_autosave?)

          saved if autosave
        end
      end
    end

    def _save_record
      record = Kredis.json(@redis_key).value

      if record&.deep_transform_keys(&:to_sym) != _snapshot
        _save_version if versioning_enabled?
        touch
        Kredis.json(@redis_key).value = _snapshot
      end
    end

    def _save_version
      if new_record?
        @_current_version = 1
      else
        record = Kredis.json(@redis_key).value
        @_current_version = record["current_version"] + 1
        @_versions = record["versions"].transform_keys(&:to_i)
      end
      @_versions[current_version] = {
        "attributes" => attributes,
        "updated_at" => Time.current.utc.to_s
      }
    end

    def _snapshot
      {
        attributes: attributes.transform_values do |value|
          case value
          when ActiveSupport::TimeWithZone
            value.utc.to_s
          when Date
            value.to_s
          else
            value
          end
        end,
        created_at: created_at,
        updated_at: @updated_at,
        previous_attributes: previous_attributes,
        current_version: current_version,
        versions: versions
      }.deep_transform_keys(&:to_sym)
    end

    def _raise_missing_foreign_key_error(reflection)
      raise AllFutures::MissingForeignKeyError, "#{reflection.klass} missing foreign key #{reflection.options[:foreign_key]}"
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

    def _validate_single_association(reflection)
      association = association_instance_get(reflection.name)
      record = association&.reader
      _association_valid?(reflection, record) if record && (record._changed_for_autosave? || _custom_validation_context?)
    end

    def _validate_collection_association(reflection)
      if (association = association_instance_get(reflection.name))
        if (records = _associated_records_to_validate_or_save(association, new_record?, reflection.options[:autosave]))
          records.each_with_index { |record, index| _association_valid?(reflection, record, index) }
        end
      end
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
