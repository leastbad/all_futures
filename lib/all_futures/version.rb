# frozen_string_literal: true

module AllFutures
  VERSION = "1.0.3"

  class Version
    def initialize(version)
      @attributes = version
    end

    class << self
      def load(model, record)
        return [] if record["versions"].nil?
        versions = record["versions"].map { |version| new(version) }
        versions
      end
    end
  end
end
