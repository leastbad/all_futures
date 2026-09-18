# frozen_string_literal: true

module ActiveEntity
  module Type
    class Date < ActiveModel::Type::Date
      include Internal::Timezone
    end
  end
end
