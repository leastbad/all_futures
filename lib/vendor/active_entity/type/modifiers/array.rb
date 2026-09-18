# frozen_string_literal: true

module ActiveEntity
  module Type
    module Modifiers
      class Array < ActiveModel::Type::Value # :nodoc:
        include ActiveModel::Type::Helpers::Mutable

        attr_reader :subtype, :delimiter
        delegate :type, :user_input_in_time_zone, :limit, :precision, :scale, to: :subtype

        def initialize(subtype, delimiter = ",")
          @subtype = subtype
          @delimiter = delimiter
        end

        def deserialize(value)
          case value
          when ::String
            type_cast_array(value.split(@delimiter), :deserialize)
          else
            super
          end
        end

        def cast(value)
          if value.is_a?(::String)
            value = value.split(@delimiter)
          end
          type_cast_array(value, :cast)
        end

        def serialize(value)
          if value.is_a?(::Array)
            casted_values = type_cast_array(value, :serialize)
            casted_values.join(@delimiter)
          else
            super
          end
        end

        def ==(other)
          other.is_a?(Array) &&
            subtype == other.subtype &&
            delimiter == other.delimiter
        end

        def map(value, &block)
          value.map(&block)
        end

        def changed_in_place?(raw_old_value, new_value)
          deserialize(raw_old_value) != new_value
        end

        def force_equality?(value)
          value.is_a?(::Array)
        end

        private

          def type_cast_array(value, method)
            if value.is_a?(::Array)
              value.map { |item| type_cast_array(item, method) }
            else
              @subtype.public_send(method, value)
            end
          end
      end
    end
  end
end
