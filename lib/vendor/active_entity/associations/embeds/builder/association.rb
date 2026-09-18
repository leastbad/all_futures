# frozen_string_literal: true

# This is the parent Association class which defines the variables
# used by all associations.
#
# The hierarchy is defined as follows:
#  Association
#    - SingularAssociation
#      - BelongsToAssociation
#      - HasOneAssociation
#    - CollectionAssociation
#      - HasManyAssociation

module ActiveEntity::Associations::Embeds::Builder # :nodoc:
  class Association #:nodoc:
    class << self
      attr_accessor :extensions
    end
    self.extensions = []

    VALID_OPTIONS = [:class_name, :anonymous_class, :validate] # :nodoc:

    def self.build(model, name, options)
      if model.dangerous_attribute_method?(name)
        raise ArgumentError, "You tried to define an association named #{name} on the model #{model.name}, but " \
                             "this will conflict with a method #{name} already defined by Active Entity. " \
                             "Please choose a different association name."
      end

      reflection = create_reflection model, name, options
      define_accessors model, reflection
      define_callbacks model, reflection
      define_validations model, reflection
      reflection
    end

    def self.create_reflection(model, name, options, &block)
      raise ArgumentError, "association names must be a Symbol" unless name.kind_of?(Symbol)

      validate_options(options)

      extension = define_extensions(model, name, &block)
      options[:extend] = [*options[:extend], extension] if extension

      ActiveEntity::Reflection.create(macro, name, nil, options, model)
    end

    def self.macro
      raise NotImplementedError
    end

    def self.valid_options(options)
      VALID_OPTIONS + Association.extensions.flat_map(&:valid_options)
    end

    def self.validate_options(options)
      options.assert_valid_keys(valid_options(options))
    end

    def self.define_extensions(model, name)
    end

    def self.define_callbacks(model, reflection)
      Association.extensions.each do |extension|
        extension.build model, reflection
      end
    end

    # Defines the setter and getter methods for the association
    # class Post < ActiveEntity::Base
    #   has_many :comments
    # end
    #
    # Post.first.comments and Post.first.comments= methods are defined by this method...
    def self.define_accessors(model, reflection)
      mixin = model.generated_association_methods
      name = reflection.name
      define_readers(mixin, name)
      define_writers(mixin, name)
    end

    def self.define_readers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}
          association(:#{name}).reader
        end
      CODE
    end

    def self.define_writers(mixin, name)
      mixin.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}=(value)
          association(:#{name}).writer(value)
        end
      CODE
    end

    def self.define_validations(_model, _reflection)
      # noop
    end

    private_class_method :macro, :valid_options, :validate_options, :define_extensions,
                         :define_callbacks, :define_accessors, :define_readers, :define_writers, :define_validations
  end
end
