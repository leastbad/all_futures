# frozen_string_literal: true

module AllFutures
  module Dirty
    def changed_attribute_names
      changed_attributes.keys
    end

    def dirty?
      changes.any?
    end

    def saved_change_to_attribute?(attr)
      attribute_previously_was(attr) != attribute_was(attr)
    end

    def saved_changes
      attributes.select { |attr| saved_change_to_attribute? attr }
    end

    def saved_changes?
      saved_changes.any?
    end
  end
end
