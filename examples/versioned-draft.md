# Versioned draft

Turn on versioning when you want history and stale-object protection:

```ruby
class Draft < AllFutures::Base
  enable_versioning!

  attribute :title, :string
  attribute :body, :string
end

draft = Draft.create(title: "v1", body: "once upon a time")
draft.update(body: "once upon a rewrite")

draft.current_version                    # => 2
draft.version(1).attributes["body"]      # => "once upon a time"
```

Two browsers, one draft:

```ruby
a = Draft.find(id)
b = Draft.find(id)

a.update(title: "from A")
b.title = "from B"
b.save # raises AllFutures::RecordStale
```

For atomic compare-and-set across processes, set `config.all_futures.atomic_locking = true`. Details in [Versioning](../usage/versioning.md).
