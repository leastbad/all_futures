# frozen_string_literal: true

module AllFutures
  # When true, versioned models save via a Redis Lua compare-and-set so two
  # processes cannot both pass a stale check and silently clobber each other.
  # Default false: the in-process guard rail (GET, check, SET) is enough for
  # most apps and avoids an EVAL on every write.
  mattr_accessor :atomic_locking, instance_accessor: false, default: false
end
