# frozen_string_literal: true

module AllFutures
  module Dirty
    extend ActiveSupport::Concern

    def attribute_change(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      attribute_was(attribute) == self[attribute] ? nil : [attribute_was(attribute), self[attribute]]
    end

    def attribute_changed?(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      changes.key? attribute.to_s
    end
    alias_method :attribute_will_change?, :attribute_changed?

    def attribute_changed!(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      public_send("#{attribute}_will_change!")
    end

    def attribute_previous_change(attribute)
      super
    end

    def attribute_will_change!(attribute)
      super
    end

    def clear_attribute_change(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      super
    end

    def clear_attribute_changes(attr_names = changed)
      super
    end

    def dirty?
      changes.any?
    end
    alias_method :changed_attributes?, :dirty?

    def previous_attributes
      attribute_names.each_with_object({}) do |attribute, hash|
        hash[attribute] = attribute_previously_was(attribute)
      end
    end

    def mutations_before_last_save
      super
    end

    def restore_attribute(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      attribute = attribute.to_s
      if attribute_changed?(attribute)
        self[attribute] = attribute_was(attribute)
        clear_attribute_change(attribute)
      end
    end

    def restore_attributes(attr_names = changed)
      attr_names.each { |attribute| _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s) }.each { |attribute| restore_attribute(attribute) }
    end

    def rollback_attribute(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      if self[attribute] != attribute_previously_was(attribute)
        self[attribute] = attribute_previously_was(attribute)
        clear_attribute_change(attribute)
      end
    end

    def rollback_attribute!(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      rollback_attribute(attribute)
      save
    end

    def rollback_attributes(attr_names = changed)
      attr_names.each { |attribute| _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s) }.each { |attribute| rollback_attribute(attribute) }
    end

    def rollback_attributes!(attr_names = changed)
      rollback_attributes(attr_names)
      save
    end

    def saved_changes?
      saved_changes.any?
    end
    alias_method :previous_changes?, :saved_changes?

    def saved_changes
      attributes.select { |attribute| attribute_previously_changed? attribute }
    end

    module ClassMethods
      def set_previous_attributes(model, record)
        tracker = ActiveModel::AttributeMutationTracker.new(model.instance_variable_get("@attributes"))
        previous_values = tracker.instance_variable_get("@attributes").instance_variable_get("@attributes")
        previous_values.each do |key, attribute|
          original = attribute.instance_variable_get("@original_attribute")
          original.instance_variable_set("@value_before_type_cast", record["previous_attributes"][key]) unless original.nil?
        end
        model.instance_variable_set "@mutations_before_last_save", tracker
      end
    end
  end
end
