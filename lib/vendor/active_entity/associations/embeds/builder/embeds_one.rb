# frozen_string_literal: true

module ActiveEntity::Associations::Embeds::Builder # :nodoc:
  class EmbedsOne < SingularAssociation #:nodoc:
    def self.macro
      :embeds_one
    end

    def self.define_validations(model, reflection)
      super
      if reflection.options[:required]
        model.validates_presence_of reflection.name, message: :required
      end
    end
  end
end
