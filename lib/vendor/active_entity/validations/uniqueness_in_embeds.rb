# frozen_string_literal: true

module ActiveEntity
  module Validations
    class UniquenessInEmbedsValidator < ActiveModel::EachValidator # :nodoc:
      ERROR_MESSAGE = "`key` option of the configuration hash must be symbol or array of symbols."

      def check_validity!
        return if key.is_a?(Symbol) || key.is_a?(Array)

        raise ArgumentError, ERROR_MESSAGE
      end

      def validate_each(record, attribute, association_or_value)
        reflection = record.class._reflect_on_association(attribute)
        if reflection
          return unless reflection.is_a?(ActiveEntity::Reflection::EmbeddedAssociationReflection)
          return unless reflection.collection?
        end

        indexed_attribute =
          if reflection
            reflection.options[:index_errors] || ActiveEntity::Base.index_nested_attribute_errors
          else
            options[:index_errors] || true
          end

        association_or_value =
          if reflection
            Array.wrap(association_or_value).reject(&:marked_for_destruction?)
          else
            Array.wrap(association_or_value)
          end

        return if association_or_value.size <= 1

        duplicate_records =
          if key.is_a? Symbol
            association_or_value.group_by(&key)
          elsif key.is_a? Array
            association_or_value.group_by { |r| key.map { |attr| r.send(attr) } }
          end
            .values
            .select { |v| v.size > 1 }
            .flatten

        return if duplicate_records.empty?

        duplicate_records.each do |r|
          if key.is_a? Symbol
            r.errors.add(key, :duplicated, **options)

            # Hack the record
            normalized_attribute = normalize_attribute(attribute, indexed_attribute, association_or_value.index(r), key)
            record.errors.import r.errors.where(key).first, attribute: normalized_attribute
          elsif key.is_a? Array
            key.each do |attr|
              r.errors.add(attr, :duplicated, **options)

              # Hack the record
              normalized_attribute = normalize_attribute(attribute, indexed_attribute, association_or_value.index(r), attr)
              record.errors.import r.errors.where(key).first, attribute: normalized_attribute
            end
          end
        end
      end

      private

        def key
          @key ||= options[:key]
        end

        def normalize_attribute(attribute, indexed_attribute, index, nested_attribute)
          if indexed_attribute
            "#{attribute}[#{index}].#{nested_attribute}"
          else
            "#{attribute}.#{nested_attribute}"
          end
        end
    end

    module ClassMethods
      # Validates whether the value of the specified attributes are unique
      # in the embedded association.
      def validates_uniqueness_in_embedding_of(*attr_names)
        validates_with UniquenessInEmbeddingValidator, _merge_attributes(attr_names)
      end
    end
  end
end
