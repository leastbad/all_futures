# frozen_string_literal: true

module AllFutures
  module Dirty
    def dirty?
      changes.any?
    end

    def saved_change_to_attribute?(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      attribute_previously_was(attribute) != attribute_was(attribute)
    end

    def saved_change_to_attribute(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      attribute_previously_was(attribute) != attribute_was(attribute) ? [attribute_previously_was(attribute), attribute_was(attribute)] : nil
    end

    def saved_changes
      attributes.select { |attribute| saved_change_to_attribute? attribute }
    end

    def saved_changes?
      saved_changes.any?
    end

    def attribute_will_change?(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      changes.key? attribute.to_s
    end

    def attribute_will_change!(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      public_send("#{attribute}_will_change!")
    end

    def clear_attribute_change(attribute)
      _raise_unknown_attribute_error(attribute) unless attributes.key?(attribute.to_s)
      super
    end
  end
end
