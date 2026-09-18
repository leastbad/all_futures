# frozen_string_literal: true

require "set"

module ActiveEntity
  module AttributeMethods
    module PrimaryKey
      extend ActiveSupport::Concern

      # Returns this record's primary key value wrapped in an array if one is
      # available.
      def to_key
        key = id
        [key] if key
      end

      # Returns the primary key column's value.
      def id
        _read_attribute(@primary_key)
      end

      # Sets the primary key column's value.
      def id=(value)
        _write_attribute(@primary_key, value)
      end

      # Queries the primary key column's value.
      def id?
        query_attribute(@primary_key)
      end

      # Returns the primary key column's value before type cast.
      def id_before_type_cast
        read_attribute_before_type_cast(@primary_key)
      end

      # Returns the primary key column's previous value.
      def id_was
        attribute_was(@primary_key)
      end

      private

        def attribute_method?(attr_name)
          attr_name == "id" || super
        end

        module ClassMethods
          ID_ATTRIBUTE_METHODS = %w(id id= id? id_before_type_cast id_was).to_set

          def instance_method_already_implemented?(method_name)
            super || primary_key && ID_ATTRIBUTE_METHODS.include?(method_name)
          end

          def dangerous_attribute_method?(method_name)
            super && !ID_ATTRIBUTE_METHODS.include?(method_name)
          end

          # Defines the primary key field -- can be overridden in subclasses.
          # Overwriting will negate any effect of the +primary_key_prefix_type+
          # setting, though.
          def primary_key
            unless defined? @primary_key
              @primary_key =
                if has_attribute?("id")
                  "id"
                else
                  nil
                end
            end

            @primary_key
          end

          # Sets the name of the primary key column.
          #
          #   class Project < ActiveEntity::Base
          #     self.primary_key = 'sysid'
          #   end
          #
          # You can also define the #primary_key method yourself:
          #
          #   class Project < ActiveEntity::Base
          #     def self.primary_key
          #       'foo_' + super
          #     end
          #   end
          #
          #   Project.primary_key # => "foo_id"
          def primary_key=(value)
            @primary_key = value && -value.to_s
          end
        end
    end
  end
end
