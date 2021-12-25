# frozen_string_literal: true

module AllFutures
  module Validations
    def attribute_valid?(attribute)
      validate
      errors[attribute].empty?
    end
  end
end
