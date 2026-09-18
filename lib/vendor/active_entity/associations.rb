# frozen_string_literal: true

require "active_support/core_ext/enumerable"
require "active_support/core_ext/string/conversions"

module ActiveEntity
  class AssociationNotFoundError < ConfigurationError #:nodoc:
    def initialize(record = nil, association_name = nil)
      if record && association_name
        super("Association named '#{association_name}' was not found on #{record.class.name}; perhaps you misspelled it?")
      else
        super("Association was not found.")
      end
    end
  end

  class InverseOfAssociationNotFoundError < ActiveEntityError #:nodoc:
    def initialize(reflection = nil, associated_class = nil)
      if reflection
        super("Could not find the inverse association for #{reflection.name} (#{reflection.options[:inverse_of].inspect} in #{associated_class.nil? ? reflection.class_name : associated_class.name})")
      else
        super("Could not find the inverse association.")
      end
    end
  end

  # See ActiveEntity::Associations::ClassMethods for documentation.
  module Associations # :nodoc:
    extend ActiveSupport::Autoload
    extend ActiveSupport::Concern
    # These classes will be loaded when associations are created.
    # So there is no need to eager load them.
    module Embeds
      extend ActiveSupport::Autoload

      autoload :Association, "active_entity/associations/embeds/association"
      autoload :SingularAssociation, "active_entity/associations/embeds/singular_association"
      autoload :CollectionAssociation, "active_entity/associations/embeds/collection_association"
      autoload :CollectionProxy, "active_entity/associations/embeds/collection_proxy"

      module Builder #:nodoc:
        autoload :Association,             "active_entity/associations/embeds/builder/association"
        autoload :SingularAssociation,     "active_entity/associations/embeds/builder/singular_association"
        autoload :CollectionAssociation,   "active_entity/associations/embeds/builder/collection_association"

        autoload :EmbeddedIn,              "active_entity/associations/embeds/builder/embedded_in"
        autoload :EmbedsOne,               "active_entity/associations/embeds/builder/embeds_one"
        autoload :EmbedsMany,              "active_entity/associations/embeds/builder/embeds_many"
      end

      eager_autoload do
        autoload :EmbeddedInAssociation
        autoload :EmbedsOneAssociation
        autoload :EmbedsManyAssociation
      end
    end

    def self.eager_load!
      super
      Embeds.eager_load!
    end
    # Returns the association instance for the given name, instantiating it if it doesn't already exist
    def association(name) #:nodoc:
      association = association_instance_get(name)

      if association.nil?
        unless reflection = self.class._reflect_on_association(name)
          raise AssociationNotFoundError.new(self, name)
        end
        association = reflection.association_class.new(self, reflection)
        association_instance_set(name, association)
      end

      association
    end

    def association_cached?(name) # :nodoc:
      @association_cache.key?(name)
    end

    def initialize_dup(*) # :nodoc:
      @association_cache = {}
      super
    end

    private

      def init_internals
        @association_cache = {}
        super
      end

      # Returns the specified association instance if it exists, +nil+ otherwise.
      def association_instance_get(name)
        @association_cache[name]
      end

      # Set the specified association instance.
      def association_instance_set(name, association)
        @association_cache[name] = association
      end

      # \Associations are a set of macro-like class methods for tying objects together through
      # foreign keys. They express relationships like "Project has one Project Manager"
      # or "Project belongs to a Portfolio". Each macro adds a number of methods to the
      # class which are specialized according to the collection or association symbol and the
      # options hash. It works much the same way as Ruby's own <tt>attr*</tt>
      # methods.
      #
      #   class Project < ActiveEntity::Base
      #     belongs_to              :portfolio
      #     has_one                 :project_manager
      #     has_many                :milestones
      #     has_and_belongs_to_many :categories
      #   end
      #
      # The project class now has the following methods (and more) to ease the traversal and
      # manipulation of its relationships:
      # * <tt>Project#portfolio</tt>, <tt>Project#portfolio=(portfolio)</tt>, <tt>Project#reload_portfolio</tt>
      # * <tt>Project#project_manager</tt>, <tt>Project#project_manager=(project_manager)</tt>, <tt>Project#reload_project_manager</tt>
      # * <tt>Project#milestones.empty?</tt>, <tt>Project#milestones.size</tt>, <tt>Project#milestones</tt>, <tt>Project#milestones<<(milestone)</tt>,
      #   <tt>Project#milestones.delete(milestone)</tt>, <tt>Project#milestones.destroy(milestone)</tt>, <tt>Project#milestones.find(milestone_id)</tt>,
      #   <tt>Project#milestones.build</tt>, <tt>Project#milestones.create</tt>
      # * <tt>Project#categories.empty?</tt>, <tt>Project#categories.size</tt>, <tt>Project#categories</tt>, <tt>Project#categories<<(category1)</tt>,
      #   <tt>Project#categories.delete(category1)</tt>, <tt>Project#categories.destroy(category1)</tt>
      #
      # === A word of warning
      #
      # Don't create associations that have the same name as {instance methods}[rdoc-ref:ActiveEntity::Core] of
      # <tt>ActiveEntity::Base</tt>. Since the association adds a method with that name to
      # its model, using an association with the same name as one provided by <tt>ActiveEntity::Base</tt> will override the method inherited through <tt>ActiveEntity::Base</tt> and will break things.
      # For instance, +attributes+ and +connection+ would be bad choices for association names, because those names already exist in the list of <tt>ActiveEntity::Base</tt> instance methods.
      module ClassMethods
        def embedded_in(name, **options)
          reflection = Embeds::Builder::EmbeddedIn.build(self, name, options)
          Reflection.add_reflection self, name, reflection
        end

        def embeds_one(name, **options)
          reflection = Embeds::Builder::EmbedsOne.build(self, name, options)
          Reflection.add_reflection self, name, reflection
        end

        def embeds_many(name, **options)
          reflection = Embeds::Builder::EmbedsMany.build(self, name, options)
          Reflection.add_reflection self, name, reflection
        end

        def association_names
          @association_names ||=
            if !abstract_class?
              reflections.keys.map(&:to_sym)
            else
              []
            end
        end

        def embeds_association_names
          @association_names ||=
            if !abstract_class?
              reflections.select { |_, r| r.embedded? }.keys.map(&:to_sym)
            else
              []
            end
        end
      end
  end
end
