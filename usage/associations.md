# Associations

Active Entity supports its own variant of nested attributes via the `embeds_one` / `embeds_many` macros. The intention is to be mostly compatible with Active Record's `accepts_nested_attributes_for` functionality.

```ruby
class Holiday < ActiveEntity::Base
  attribute :date, :date
  validates :date, presence: true
end

class HolidaysForm < ActiveEntity::Base
  embeds_many :holidays
  accepts_nested_attributes_for :holidays, reject_if: :all_blank
end
```

[https://github.com/jasl/activeentity/#nested-attributes](https://github.com/jasl/activeentity/#nested-attributes)
