# frozen_string_literal: true

module ActiveEntity
  module Validations
    class SubsetValidator < ActiveModel::EachValidator # :nodoc:
      ERROR_MESSAGE = "An object with the method #include? or a proc, lambda or symbol is required, " \
                      "and must be supplied as the :in (or :within) option of the configuration hash"

      def check_validity!
        unless delimiter.respond_to?(:include?) || delimiter.respond_to?(:call) || delimiter.respond_to?(:to_sym)
          raise ArgumentError, ERROR_MESSAGE
        end
      end

      def validate_each(record, attribute, value)
        if value && !value.respond_to?(:to_a)
          raise ArgumentError, "#{record} can't respond `to_a`."
        end

        unless subset?(record, value)
          record.errors.add(attribute, :non_subset, **options.except(:in, :within).merge(value: value))
        end
      end

      private

        def delimiter
          @delimiter ||= options[:in] || options[:within]
        end

        def subset?(record, value)
          enumerable = value.to_a
          members =
            if delimiter.respond_to?(:call)
              delimiter.call(record)
            elsif delimiter.respond_to?(:to_sym)
              record.send(delimiter)
            else
              delimiter
            end

          (members & enumerable).size == enumerable.size
        end
    end

    module ClassMethods
      # Validates whether the value of the specified attribute is available in a
      # particular enumerable object.
      #
      #   class Person < ActiveRecord::Base
      #     validates :tags, subset: %w( m f )
      #     validates_subset_of :tags, in: %w( m f )
      #     validates_inclusion_of :tags, in: %w( m f ), message: "tag %{value} is not included in the list"
      #     validates_inclusion_of :tags, in: ->(record) { record.available_tags }
      #     validates_inclusion_of :tags, in: :available_tags
      #   end
      #
      # Configuration options:
      # * <tt>:in</tt> - An enumerable object of available items. This can be
      #   supplied as a proc, lambda or symbol which returns an enumerable. If the
      #   enumerable is a numerical, time or datetime range the test is performed
      #   with <tt>Range#cover?</tt>, otherwise with <tt>include?</tt>. When using
      #   a proc or lambda the instance under validation is passed as an argument.
      # * <tt>:within</tt> - A synonym(or alias) for <tt>:in</tt>
      # * <tt>:message</tt> - Specifies a custom error message (default is: "is
      #   not included in the list").
      #
      # There is also a list of default options supported by every validator:
      # +:if+, +:unless+, +:on+, +:allow_nil+, +:allow_blank+, and +:strict+.
      # See <tt>ActiveModel::Validations#validates</tt> for more information
      def validates_subset_of(*attr_names)
        validates_with SubsetValidator, _merge_attributes(attr_names)
      end
    end
  end
end
