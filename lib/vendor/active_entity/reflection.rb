# frozen_string_literal: true

require "active_support/core_ext/string/filters"
require "concurrent/map"

module ActiveEntity
  # = Active Entity Reflection
  module Reflection # :nodoc:
    extend ActiveSupport::Concern

    included do
      class_attribute :_reflections, instance_writer: false, default: {}
      class_attribute :aggregate_reflections, instance_writer: false, default: {}
    end

    class << self
      def create(macro, name, scope, options, ar_or_ae)
        reflection_class_for(macro).new(name, scope, options, ar_or_ae)

        # TODO: Support bridge to Active Entity
        # reflection = reflection_class_for(macro).new(name, scope, options, ar_or_ae)
        # options[:through] ? ActiveRecord::ThroughReflection.new(reflection) : reflection
      end

      def add_reflection(ar_or_ae, name, reflection)
        ar_or_ae.clear_reflections_cache
        name = name.to_s
        ar_or_ae._reflections = ar_or_ae._reflections.except(name).merge!(name => reflection)
      end

      def add_aggregate_reflection(ae, name, reflection)
        ae.aggregate_reflections = ae.aggregate_reflections.merge(name.to_s => reflection)
      end

      private

        def reflection_class_for(macro)
          case macro
          when :composed_of
            AggregateReflection
          when :embedded_in
            EmbeddedInReflection
          when :embeds_one
            EmbedsOneReflection
          when :embeds_many
            EmbedsManyReflection
          else
            raise "Unsupported Macro: #{macro}"
          end
        end
    end

    # \Reflection enables the ability to examine the associations and aggregations of
    # Active Entity classes and objects. This information, for example,
    # can be used in a form builder that takes an Active Entity object
    # and creates input fields for all of the attributes depending on their type
    # and displays the associations to other objects.
    #
    # MacroReflection class has info for AggregateReflection and AssociationReflection
    # classes.
    module ClassMethods
      # Returns an array of AggregateReflection objects for all the aggregations in the class.
      def reflect_on_all_aggregations
        aggregate_reflections.values
      end

      # Returns the AggregateReflection object for the named +aggregation+ (use the symbol).
      #
      #   Account.reflect_on_aggregation(:balance) # => the balance AggregateReflection
      #
      def reflect_on_aggregation(aggregation)
        aggregate_reflections[aggregation.to_s]
      end

      # Returns a Hash of name of the reflection as the key and an AssociationReflection as the value.
      #
      #   Account.reflections # => {"balance" => AggregateReflection}
      #
      def reflections
        @__reflections ||= begin
                             ref = {}

                             _reflections.each do |name, reflection|
                               parent_reflection = reflection.parent_reflection

                               if parent_reflection
                                 parent_name = parent_reflection.name
                                 ref[parent_name.to_s] = parent_reflection
                               else
                                 ref[name] = reflection
                               end
                             end

                             ref
                           end
      end

      # Returns an array of AssociationReflection objects for all the
      # associations in the class. If you only want to reflect on a certain
      # association type, pass in the symbol (<tt>:has_many</tt>, <tt>:has_one</tt>,
      # <tt>:belongs_to</tt>) as the first parameter.
      #
      # Example:
      #
      #   Account.reflect_on_all_associations             # returns an array of all associations
      #   Account.reflect_on_all_associations(:has_many)  # returns an array of all has_many associations
      #
      def reflect_on_all_associations(macro = nil)
        association_reflections = reflections.values
        association_reflections.select! { |reflection| reflection.macro == macro } if macro
        association_reflections
      end

      # Returns the AssociationReflection object for the +association+ (use the symbol).
      #
      #   Account.reflect_on_association(:owner)             # returns the owner AssociationReflection
      #   Invoice.reflect_on_association(:line_items).macro  # returns :has_many
      #
      def reflect_on_association(association)
        reflections[association.to_s]
      end

      def _reflect_on_association(association) #:nodoc:
        _reflections[association.to_s]
      end

      def clear_reflections_cache # :nodoc:
        @__reflections = nil
      end
    end

    # Holds all the methods that are shared between MacroReflection and ThroughReflection.
    #
    #   AbstractReflection
    #     MacroReflection
    #       AggregateReflection
    #       AssociationReflection
    #         HasManyReflection
    #         HasOneReflection
    #         BelongsToReflection
    #         HasAndBelongsToManyReflection
    #     ThroughReflection
    #     PolymorphicReflection
    #     RuntimeReflection

    class AbstractReflection
      def embedded?
        false
      end
    end

    class AbstractEmbeddedReflection < AbstractReflection # :nodoc:
      def embedded?
        true
      end

      def through_reflection?
        false
      end

      # Returns a new, unsaved instance of the associated class. +attributes+ will
      # be passed to the class's constructor.
      def build_association(attributes, &block)
        klass.new(attributes, &block)
      end

      # Returns the class name for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>'Money'</tt>
      # <tt>has_many :clients</tt> returns <tt>'Client'</tt>
      def class_name
        @class_name ||= (options[:class_name] || derive_class_name).to_s
      end

      def inverse_of
        return unless inverse_name

        @inverse_of ||= klass._reflect_on_association inverse_name
      end

      def check_validity_of_inverse!
        if has_inverse? && inverse_of.nil?
          raise InverseOfAssociationNotFoundError.new(self)
        end
      end

      protected

        def actual_source_reflection # FIXME: this is a horrible name
          self
        end
    end

    # Base class for AggregateReflection and AssociationReflection. Objects of
    # AggregateReflection and AssociationReflection are returned by the Reflection::ClassMethods.
    class MacroEmbeddedReflection < AbstractEmbeddedReflection
      # Returns the name of the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>:balance</tt>
      # <tt>has_many :clients</tt> returns <tt>:clients</tt>
      attr_reader :name

      # Returns the hash of options used for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns <tt>{ class_name: "Money" }</tt>
      # <tt>has_many :clients</tt> returns <tt>{}</tt>
      attr_reader :options

      attr_reader :active_entity

      def initialize(name, scope, options, active_entity)
        @name          = name
        @scope         = scope
        @options       = options
        @active_entity = active_entity
        @klass         = options[:anonymous_class]
      end

      # Returns the class for the macro.
      #
      # <tt>composed_of :balance, class_name: 'Money'</tt> returns the Money class
      # <tt>has_many :clients</tt> returns the Client class
      #
      #   class Company < ActiveEntity::Base
      #     has_many :clients
      #   end
      #
      #   Company.reflect_on_association(:clients).klass
      #   # => Client
      #
      # <b>Note:</b> Do not call +klass.new+ or +klass.create+ to instantiate
      # a new association object. Use +build_association+ or +create_association+
      # instead. This allows plugins to hook into association object creation.
      def klass
        @klass ||= compute_class(class_name)
      end

      def compute_class(name)
        name.constantize
      end

      # Returns +true+ if +self+ and +other_aggregation+ have the same +name+ attribute, +active_entity+ attribute,
      # and +other_aggregation+ has an options hash assigned to it.
      def ==(other_aggregation)
        super ||
          other_aggregation.kind_of?(self.class) &&
            name == other_aggregation.name &&
            !other_aggregation.options.nil? &&
            active_entity == other_aggregation.active_entity
      end

      private

        def derive_class_name
          name.to_s.camelize
        end
    end

    # Holds all the metadata about an aggregation as it was specified in the
    # Active Entity class.
    class AggregateReflection < MacroEmbeddedReflection #:nodoc:
      def mapping
        mapping = options[:mapping] || [name, name]
        mapping.first.is_a?(Array) ? mapping : [mapping]
      end
    end

    # Holds all the metadata about an association as it was specified in the
    # Active Entity class.
    class EmbeddedAssociationReflection < MacroEmbeddedReflection #:nodoc:
      def compute_class(name)
        active_entity.send(:compute_type, name)
      end

      attr_reader :type
      attr_accessor :parent_reflection # Reflection

      def initialize(name, scope, options, active_entity)
        super
        @constructable = calculate_constructable(macro, options)

        if options[:class_name] && options[:class_name].class == Class
          raise ArgumentError, "A class was passed to `:class_name` but we are expecting a string."
        end
      end

      def constructable? # :nodoc:
        @constructable
      end

      def check_validity!
        check_validity_of_inverse!
      end

      def nested?
        false
      end

      def has_inverse?
        inverse_name
      end

      # Returns the macro type.
      #
      # <tt>has_many :clients</tt> returns <tt>:has_many</tt>
      def macro; raise NotImplementedError; end

      # Returns whether or not this association reflection is for a collection
      # association. Returns +true+ if the +macro+ is either +has_many+ or
      # +has_and_belongs_to_many+, +false+ otherwise.
      def collection?
        false
      end

      # Returns whether or not the association should be validated as part of
      # the parent's validation.
      #
      # Unless you explicitly disable validation with
      # <tt>validate: false</tt>, validation will take place when:
      #
      # * you explicitly enable validation; <tt>validate: true</tt>
      # * you use autosave; <tt>autosave: true</tt>
      # * the association is a +has_many+ association
      def validate?
        !!options[:validate]
      end

      # Returns +true+ if +self+ is a +belongs_to+ reflection.
      def embedded_in?; false; end

      # Returns +true+ if +self+ is a +has_one+ reflection.
      def embeds_one?; false; end

      def association_class; raise NotImplementedError; end

      VALID_AUTOMATIC_INVERSE_MACROS = [:embeds_many, :embeds_one, :embedded_in]

      def extensions
        Array(options[:extend])
      end

      private

        def calculate_constructable(_macro, _options)
          true
        end

        # Attempts to find the inverse association name automatically.
        # If it cannot find a suitable inverse association name, it returns
        # +nil+.
        def inverse_name
          unless defined?(@inverse_name)
            @inverse_name = options.fetch(:inverse_of) { automatic_inverse_of }
          end

          @inverse_name
        end

        # returns either +nil+ or the inverse association name that it finds.
        def automatic_inverse_of
          return unless can_find_inverse_of_automatically?(self)

          inverse_name_candidates =
            begin
              active_entity_name = active_entity.name.demodulize
              [active_entity_name, ActiveSupport::Inflector.pluralize(active_entity_name)]
            end

          inverse_name_candidates.map! do |candidate|
            ActiveSupport::Inflector.underscore(candidate).to_sym
          end

          inverse_name_candidates.detect do |inverse_name|
            begin
              reflection = klass._reflect_on_association(inverse_name)
            rescue NameError
              # Give up: we couldn't compute the klass type so we won't be able
              # to find any associations either.
              reflection = false
            end

            valid_inverse_reflection?(reflection)
          end
        end

        # Checks if the inverse reflection that is returned from the
        # +automatic_inverse_of+ method is a valid reflection. We must
        # make sure that the reflection's active_entity name matches up
        # with the current reflection's klass name.
        def valid_inverse_reflection?(reflection)
          reflection &&
            klass <= reflection.active_entity &&
            can_find_inverse_of_automatically?(reflection)
        end

        # Checks to see if the reflection doesn't have any options that prevent
        # us from being able to guess the inverse automatically. First, the
        # <tt>inverse_of</tt> option cannot be set to false. Second, we must
        # have <tt>has_many</tt>, <tt>has_one</tt>, <tt>belongs_to</tt> associations.
        # Third, we must not have options such as <tt>:foreign_key</tt>
        # which prevent us from correctly guessing the inverse association.
        #
        # Anything with a scope can additionally ruin our attempt at finding an
        # inverse, so we exclude reflections with scopes.
        def can_find_inverse_of_automatically?(reflection)
          reflection.options[:inverse_of] != false &&
            VALID_AUTOMATIC_INVERSE_MACROS.include?(reflection.macro)
        end

        def derive_class_name
          class_name = name.to_s
          class_name = class_name.singularize if collection?
          class_name.camelize
        end
    end

    class EmbedsManyReflection < EmbeddedAssociationReflection # :nodoc:
      def macro; :embeds_many; end

      def collection?; true; end

      def association_class
        Associations::Embeds::EmbedsManyAssociation
      end
    end

    class EmbedsOneReflection < EmbeddedAssociationReflection # :nodoc:
      def macro; :embeds_one; end

      def embeds_one?; true; end

      def association_class
        Associations::Embeds::EmbedsOneAssociation
      end
    end

    class EmbeddedInReflection < EmbeddedAssociationReflection # :nodoc:
      def macro; :embedded_in; end

      def embedded_in?; true; end

      def association_class
        Associations::Embeds::EmbeddedInAssociation
      end
    end
  end
end
