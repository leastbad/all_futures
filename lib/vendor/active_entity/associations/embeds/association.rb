# frozen_string_literal: true

require "active_support/core_ext/array/wrap"

module ActiveEntity
  module Associations
    module Embeds
      # = Active Entity Associations
      #
      # This is the root class of all associations ('+ Foo' signifies an included module Foo):
      #
      #   Association
      #     SingularAssociation
      #       HasOneAssociation + ForeignAssociation
      #         HasOneThroughAssociation + ThroughAssociation
      #       BelongsToAssociation
      #         BelongsToPolymorphicAssociation
      #     CollectionAssociation
      #       HasManyAssociation + ForeignAssociation
      #         HasManyThroughAssociation + ThroughAssociation
      class Association #:nodoc:
        attr_reader :owner, :target, :reflection

        delegate :options, to: :reflection

        def initialize(owner, reflection)
          reflection.check_validity!

          @owner, @reflection = owner, reflection

          @target = nil
          @inversed = false
        end

        # Has the \target been already \loaded?
        def loaded?
          true
        end

        # Sets the target of this association to <tt>\target</tt>, and the \loaded flag to +true+.
        attr_writer :target

        # Set the inverse association, if possible
        def set_inverse_instance(record)
          if inverse = inverse_association_for(record)
            inverse.inversed_from(owner)
          end
          record
        end

        # Remove the inverse association, if possible
        def remove_inverse_instance(record)
          if inverse = inverse_association_for(record)
            inverse.inversed_from(nil)
          end
        end

        def inversed_from(record)
          self.target = record
          @inversed = !!record
        end

        # Returns the class of the target. belongs_to polymorphic overrides this to look at the
        # polymorphic_type field on the owner.
        def klass
          reflection.klass
        end

        def extensions
          reflection.extensions
        end

        # We can't dump @reflection and @through_reflection since it contains the scope proc
        def marshal_dump
          ivars = (instance_variables - [:@reflection, :@through_reflection]).map { |name| [name, instance_variable_get(name)] }
          [@reflection.name, ivars]
        end

        def marshal_load(data)
          reflection_name, ivars = data
          ivars.each { |name, val| instance_variable_set(name, val) }
          @reflection = @owner.class._reflect_on_association(reflection_name)
        end

        def initialize_attributes(record, attributes = {}) #:nodoc:
          record.assign_attributes attributes if attributes.any?
          set_inverse_instance(record)
        end

        private

          # Raises ActiveEntity::AssociationTypeMismatch unless +record+ is of
          # the kind of the class of the associated objects. Meant to be used as
          # a sanity check when you are about to assign an associated record.
          def raise_on_type_mismatch!(record)
            unless record.is_a?(reflection.klass)
              fresh_class = reflection.class_name.safe_constantize
              unless fresh_class && record.is_a?(fresh_class)
                message = "#{reflection.class_name}(##{reflection.klass.object_id}) expected, "\
                  "got #{record.inspect} which is an instance of #{record.class}(##{record.class.object_id})"
                raise ActiveEntity::AssociationTypeMismatch, message
              end
            end
          end

          def inverse_association_for(record)
            if invertible_for?(record)
              record.association(inverse_reflection_for(record).name)
            end
          end

          # Can be redefined by subclasses, notably polymorphic belongs_to
          # The record parameter is necessary to support polymorphic inverses as we must check for
          # the association in the specific class of the record.
          def inverse_reflection_for(record)
            reflection.inverse_of
          end

          # Returns true if inverse association on the given record needs to be set.
          # This method is redefined by subclasses.
          def invertible_for?(record)
            inverse_reflection_for(record)
          end

          def build_record(attributes)
            reflection.build_association(attributes) do |record|
              initialize_attributes(record, attributes)
              yield(record) if block_given?
            end
          end
      end
    end
  end
end
