# frozen_string_literal: true

module ActiveEntity
  module Type
    module Modifiers
      class ArrayWithoutBlank < Array # :nodoc:
        private

          def type_cast_array(value, method)
            if value.is_a?(::Array)
              ::ArrayWithoutBlank.new value.map { |item| type_cast_array(item, method) }
            else
              @subtype.public_send(method, value)
            end
          end
      end
    end
  end
end
