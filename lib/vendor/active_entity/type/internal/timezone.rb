# frozen_string_literal: true

module ActiveEntity
  module Type
    module Internal
      module Timezone
        def is_utc?
          ActiveEntity::Base.default_timezone == :utc
        end

        def default_timezone
          ActiveEntity::Base.default_timezone
        end
      end
    end
  end
end
