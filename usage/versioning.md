# Versioning

All Futures can keep a complete history of every saved change to your model. Versioning is opt-in, per class:

```ruby
class Draft < AllFutures::Base
  enable_versioning!

  attribute :body, :string
end
```

## How it works

Every save that actually changes the record appends a new version to the model's history and increments `current_version`. Saving a record with no changes is a no-op: nothing is written and no version is created.

```ruby
draft = Draft.create(body: "first")
draft.current_version # => 1

draft.update(body: "second")
draft.current_version # => 2

draft.save            # no changes
draft.current_version # => 2
```

Version history survives round trips through Redis:

```ruby
found = Draft.find(draft.id)
found.current_version              # => 2
found.version(1).attributes["body"] # => "first"
found.version(2).attributes["body"] # => "second"
```

## Accessing versions

- `current_version` returns the current version number, or `nil` for non-versioned models
- `version(n)` returns a `Version` struct with `attributes` and `updated_at`; raises `AllFutures::VersionNotFound` for unknown versions
- `versions` returns the raw version hash, keyed by version number

## Skipping versioning

Use `without_versioning` to save changes without recording a version:

```ruby
draft.without_versioning do |record|
  record.update(body: "stealth edit")
end

draft.current_version # unchanged
```

You can also toggle versioning on an instance with `disable_versioning!` and `enable_versioning!`.

## Optimistic locking

Versioned models are protected against concurrent updates. If another process saves a newer version after you loaded your copy, your save raises `AllFutures::RecordStale` instead of silently clobbering their changes:

```ruby
copy_a = Draft.find(id)
copy_b = Draft.find(id)

copy_a.update(body: "from a") # version bumped

copy_b.body = "from b"
copy_b.save # raises AllFutures::RecordStale
```

Rescue `RecordStale` to implement retry or merge behavior. Saving a stale copy that has no changes of its own is a harmless no-op.

Note that the version check and the write are not executed atomically, so an extremely tight race between two processes can still result in a lost update. Treat this as a guard rail, not a transactional guarantee. Models without versioning enabled have no stale protection: last write wins.

## Storage notes

Versions are stored inside the same Redis JSON document as the record itself, so history grows without bound as you save. For long-lived, frequently updated models, consider whether you need versioning enabled, or reach for `without_versioning` on high-frequency writes.
