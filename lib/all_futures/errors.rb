# frozen_string_literal: true

module AllFutures
  class InvalidAttribute < StandardError; end

  class ParentModelNotSavedYet < StandardError; end

  class ReadOnlyRecord < StandardError; end

  class RecordInvalid < StandardError; end

  class RecordNotFound < StandardError; end

  class RecordNotDestroyed < StandardError; end

  class RecordNotSaved < StandardError; end

  class SoleRecordExceeded < StandardError; end

  class VersionNotFound < StandardError; end
end
