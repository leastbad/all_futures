# frozen_string_literal: true

module ActiveEntity
  # = Active Entity Errors
  #
  # Generic Active Entity exception class.
  class ActiveEntityError < StandardError
  end

  # Raised when an object assigned to an association has an incorrect type.
  #
  #   class Ticket < ActiveEntity::Base
  #     has_many :patches
  #   end
  #
  #   class Patch < ActiveEntity::Base
  #     belongs_to :ticket
  #   end
  #
  #   # Comments are not patches, this assignment raises AssociationTypeMismatch.
  #   @ticket.patches << Comment.new(content: "Please attach tests to your patch.")
  class AssociationTypeMismatch < ActiveEntityError
  end

  # Raised when unserialized object's type mismatches one specified for serializable field.
  class SerializationTypeMismatch < ActiveEntityError
  end

  # Raised when association is being configured improperly or user tries to use
  # offset and limit together with
  # {ActiveEntity::Base.has_many}[rdoc-ref:Associations::ClassMethods#has_many] or
  # {ActiveEntity::Base.has_and_belongs_to_many}[rdoc-ref:Associations::ClassMethods#has_and_belongs_to_many]
  # associations.
  class ConfigurationError < ActiveEntityError
  end

  # Raised when attribute has a name reserved by Active Entity (when attribute
  # has name of one of Active Entity instance methods).
  class DangerousAttributeError < ActiveEntityError
  end

  # Raised when unknown attributes are supplied via mass assignment.
  UnknownAttributeError = ActiveModel::UnknownAttributeError

  # Raised when an error occurred while doing a mass assignment to an attribute through the
  # {ActiveEntity::Base#attributes=}[rdoc-ref:AttributeAssignment#attributes=] method.
  # The exception has an +attribute+ property that is the name of the offending attribute.
  class AttributeAssignmentError < ActiveEntityError
    attr_reader :exception, :attribute

    def initialize(message = nil, exception = nil, attribute = nil)
      super(message)
      @exception = exception
      @attribute = attribute
    end
  end

  # Raised when there are multiple errors while doing a mass assignment through the
  # {ActiveEntity::Base#attributes=}[rdoc-ref:AttributeAssignment#attributes=]
  # method. The exception has an +errors+ property that contains an array of AttributeAssignmentError
  # objects, each corresponding to the error while assigning to an attribute.
  class MultiparameterAssignmentErrors < ActiveEntityError
    attr_reader :errors

    def initialize(errors = nil)
      @errors = errors
    end
  end
end
