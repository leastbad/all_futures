# frozen_string_literal: true

module ActiveEntity::Associations::Embeds::Builder # :nodoc:
  class EmbeddedIn < SingularAssociation #:nodoc:
    def self.macro
      :embedded_in
    end

    def self.valid_options(options)
      super + [:default]
    end

    def self.define_callbacks(model, reflection)
      super
      add_default_callbacks(model, reflection) if reflection.options[:default]
    end

    def self.add_default_callbacks(model, reflection)
      model.before_validation lambda { |o|
        o.association(reflection.name).default(&reflection.options[:default])
      }
    end

    def self.define_validations(model, reflection)
      if reflection.options.key?(:required)
        reflection.options[:optional] = !reflection.options.delete(:required)
      end

      required = !reflection.options[:optional]

      super

      if required
        model.validates_presence_of reflection.name, message: :required
      end
    end
  end
end
