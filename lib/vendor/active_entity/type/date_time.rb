# frozen_string_literal: true

module ActiveEntity
  module Type
    class DateTime < ActiveModel::Type::DateTime
      include Internal::Timezone
    end
  end
end
