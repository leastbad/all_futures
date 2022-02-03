# frozen_string_literal: true

module AllFutures
  class DeleteRestrictionError < StandardError
    def initialize(name = nil)
      if name
        super("Cannot delete record because of dependent #{name}")
      else
        super("Delete restriction error.")
      end
    end
  end

  class InvalidAttribute < StandardError; end

  class InvalidDependentOption < StandardError; end

  class MissingForeignKeyError < StandardError; end

  class ParentModelNotSavedYet < StandardError; end

  class ReadOnlyRecord < StandardError; end

  class RecordInvalid < StandardError; end

  class RecordNotFound < StandardError; end

  class RecordNotDestroyed < StandardError; end

  class RecordNotSaved < StandardError; end

  class SoleRecordExceeded < StandardError; end

  class VersionNotFound < StandardError; end
end
