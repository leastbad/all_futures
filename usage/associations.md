# Associations

{% hint style="warning" %}
Association persistence is **experimental**. The core attribute, persistence, dirty tracking and versioning APIs are stable, but the embedded association layer described below is newer and its semantics may still change.
{% endhint %}

All Futures supports embedded associations via the `embeds_one` / `embeds_many` / `embedded_in` macros provided by Active Entity, extended with a persistence layer: associated All Futures models are saved as their own Redis records, linked by a foreign key.

```ruby
class Government < AllFutures::Base
  embeds_many :spies, dependent: :destroy, autosave: true
end

class Spy < AllFutures::Base
  attribute :government_id
  attribute :codename, :string
  embedded_in :government
end

government = Government.new
spy = government.spies.build(codename: "alpha")
government.save

spy.persisted?     # => true
spy.government_id  # => government.id
```

## Lazy loading after find

Like Active Record, `find` does **not** eager-load children. The first time you touch an association on a persisted parent, All Futures loads the members from a Redis SET index (`Government:<id>:spies`) and hydrates the proxy:

```ruby
found = Government.find(government.id)
found.spies.size           # => 1
found.spies.first.codename # => "alpha"
```

Children saved on their own (with the foreign key set) are added to the same index, so they show up when the parent is loaded later.

## Options

- `foreign_key:` — the attribute on the child that stores the owner's id. Defaults to the association name plus `_id` on `embedded_in` (for example `government_id`), and to the owner's singular model name plus `_id` on `embeds_one` / `embeds_many`. The child must declare this attribute, or `AllFutures::MissingForeignKeyError` is raised on save.
- `autosave:` — when `true`, saving the owner also saves loaded children that have unsaved changes.
- `dependent:` — what happens to children when the owner is destroyed:
  - `:destroy` — children are destroyed, running their callbacks
  - `:delete` — children are removed from Redis without callbacks
  - `:nullify` — children survive, with their foreign key set to `nil`
  - `:restrict_with_exception` — raises `AllFutures::DeleteRestrictionError` if any children exist
  - `:restrict_with_error` — aborts the destroy (returns `false`) and adds an error to the owner's `:base`

## Nested attributes

`accepts_nested_attributes_for` works much like Active Record's:

```ruby
class HolidaysForm < AllFutures::Base
  embeds_many :holidays
  accepts_nested_attributes_for :holidays, reject_if: :all_blank
end
```

## Known limitations

- Children saved through their owner skip version creation (they are saved `without_versioning`), so a versioned child only accrues versions when saved directly.
- The Redis SET index is an implementation detail; do not rely on its key names outside All Futures.
