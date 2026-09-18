# frozen_string_literal: true

require "active_support/core_ext/module/attribute_accessors"

module ActiveEntity
  module AttributeMethods
    module Dirty
      extend ActiveSupport::Concern
      include ActiveEntity::AMAttributeMethods

      included do
        attribute_method_suffix "_changed?", "_change", "_will_change!", "_was"
        attribute_method_suffix "_previously_changed?", "_previous_change", "_previously_was"
        attribute_method_affix prefix: "restore_", suffix: "!"
        attribute_method_affix prefix: "clear_", suffix: "_change"
      end

      def initialize_dup(other) # :nodoc:
        super
        if self.class.respond_to?(:_default_attributes)
          @attributes = self.class._default_attributes.map do |attr|
            attr.with_value_from_user(@attributes.fetch_value(attr.name))
          end
        end
        @mutations_from_database = nil
      end

      def as_json(options = {}) # :nodoc:
        options[:except] = [*options[:except], "mutations_from_database", "mutations_before_last_save"]
        super(options)
      end

      # Clears dirty data and moves +changes+ to +previous_changes+ and
      # +mutations_from_database+ to +mutations_before_last_save+ respectively.
      def changes_applied
        unless defined?(@attributes)
          mutations_from_database.finalize_changes
        end
        @mutations_before_last_save = mutations_from_database
        forget_attribute_assignments
        @mutations_from_database = nil
      end

      # Returns +true+ if any of the attributes has unsaved changes, +false+ otherwise.
      #
      #   person.changed? # => false
      #   person.name = 'bob'
      #   person.changed? # => true
      def changed?
        mutations_from_database.any_changes?
      end

      # Returns an array with the name of the attributes with unsaved changes.
      #
      #   person.changed # => []
      #   person.name = 'bob'
      #   person.changed # => ["name"]
      def changed
        mutations_from_database.changed_attribute_names
      end

      # Dispatch target for <tt>*_changed?</tt> attribute methods.
      def attribute_changed?(attr_name, **options) # :nodoc:
        mutations_from_database.changed?(attr_name.to_s, **options)
      end

      # Dispatch target for <tt>*_was</tt> attribute methods.
      def attribute_was(attr_name) # :nodoc:
        mutations_from_database.original_value(attr_name.to_s)
      end

      # Dispatch target for <tt>*_previously_changed?</tt> attribute methods.
      def attribute_previously_changed?(attr_name, **options) # :nodoc:
        mutations_before_last_save.changed?(attr_name.to_s, **options)
      end

      # Dispatch target for <tt>*_previously_was</tt> attribute methods.
      def attribute_previously_was(attr_name) # :nodoc:
        mutations_before_last_save.original_value(attr_name.to_s)
      end

      # Restore all previous data of the provided attributes.
      def restore_attributes(attr_names = changed)
        attr_names.each { |attr_name| restore_attribute!(attr_name) }
      end

      # Clears all dirty data: current changes and previous changes.
      def clear_changes_information
        @mutations_before_last_save = nil
        forget_attribute_assignments
        @mutations_from_database = nil
      end

      def clear_attribute_changes(attr_names)
        attr_names.each do |attr_name|
          clear_attribute_change(attr_name)
        end
      end

      # Returns a hash of the attributes with unsaved changes indicating their original
      # values like <tt>attr => original value</tt>.
      #
      #   person.name # => "bob"
      #   person.name = 'robert'
      #   person.changed_attributes # => {"name" => "bob"}
      def changed_attributes
        mutations_from_database.changed_values
      end

      # Returns a hash of changed attributes indicating their original
      # and new values like <tt>attr => [original value, new value]</tt>.
      #
      #   person.changes # => {}
      #   person.name = 'bob'
      #   person.changes # => { "name" => ["bill", "bob"] }
      def changes
        mutations_from_database.changes
      end

      # Returns a hash of attributes that were changed before the model was saved.
      #
      #   person.name # => "bob"
      #   person.name = 'robert'
      #   person.save
      #   person.previous_changes # => {"name" => ["bob", "robert"]}
      def previous_changes
        mutations_before_last_save.changes
      end

      def attribute_changed_in_place?(attr_name) # :nodoc:
        mutations_from_database.changed_in_place?(attr_name.to_s)
      end

      private
        def clear_attribute_change(attr_name)
          mutations_from_database.forget_change(attr_name.to_s)
        end

        def mutations_from_database
          @mutations_from_database ||= if defined?(@attributes)
                                         ActiveModel::AttributeMutationTracker.new(@attributes)
                                       else
                                         ActiveModel::ForcedMutationTracker.new(self)
                                       end
        end

        def forget_attribute_assignments
          @attributes = @attributes.map(&:forgetting_assignment) if defined?(@attributes)
        end

        def mutations_before_last_save
          @mutations_before_last_save ||= ActiveModel::NullMutationTracker.instance
        end

        # Dispatch target for <tt>*_change</tt> attribute methods.
        def attribute_change(attr_name)
          mutations_from_database.change_to_attribute(attr_name.to_s)
        end

        # Dispatch target for <tt>*_previous_change</tt> attribute methods.
        def attribute_previous_change(attr_name)
          mutations_before_last_save.change_to_attribute(attr_name.to_s)
        end

        # Dispatch target for <tt>*_will_change!</tt> attribute methods.
        def attribute_will_change!(attr_name)
          mutations_from_database.force_change(attr_name.to_s)
        end

        # Dispatch target for <tt>restore_*!</tt> attribute methods.
        def restore_attribute!(attr_name)
          attr_name = attr_name.to_s
          if attribute_changed?(attr_name)
            __send__("#{attr_name}=", attribute_was(attr_name))
            clear_attribute_change(attr_name)
          end
        end
    end
  end
end
