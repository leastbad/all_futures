# Associations

All Futures supports its own variant of [nested attributes](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html) via the `embeds_one` / `embeds_many` methods provided by Active Entity. They are mostly compatible with Active Record's `accepts_nested_attributes_for` functionality.

```ruby
class Holiday < AllFutures::Base
  attribute :date, :date
  validates :date, presence: true
end

class HolidaysForm < AllFutures::Base
  embeds_many :holidays
  accepts_nested_attributes_for :holidays, reject_if: :all_blank
end
```
