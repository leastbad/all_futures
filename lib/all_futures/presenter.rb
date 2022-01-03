# frozen_string_literal: true

module AllFutures
  module Presenter
    attr_reader :updated_at

    def max_updated_column_timestamp
      @updated_at&.to_time
    end

    def reject
      attributes
    end

    def to_dom_id
      [self.class.name.underscore.dasherize.gsub("/", "--"), id].join("-")
    end

    def to_h
      attributes
    end

    def to_s
      inspect
    end
  end
end
