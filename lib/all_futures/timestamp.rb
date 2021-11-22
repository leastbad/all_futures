# frozen_string_literal: true

module AllFutures
  module Timestamp
    def max_updated_column_timestamp
      attributes[:updated_at]&.to_time
    end
  end
end
