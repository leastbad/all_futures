# frozen_string_literal: true

module AllFutures
  module Timestamp
    attr_reader :updated_at

    def max_updated_column_timestamp
      @updated_at&.to_time
    end
  end
end
