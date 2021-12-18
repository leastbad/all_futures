# Validations

```ruby
class Book < ActiveEntity::Base
  attribute :title, :string
  validates :title, presence: true
end
```

Supported Active Record validations:

* [acceptance](https://guides.rubyonrails.org/active\_record\_validations.html#acceptance)
* [confirmation](https://guides.rubyonrails.org/active\_record\_validations.html#confirmation)
* [exclusion](https://guides.rubyonrails.org/active\_record\_validations.html#exclusion)
* [format](https://guides.rubyonrails.org/active\_record\_validations.html#format)
* [inclusion](https://guides.rubyonrails.org/active\_record\_validations.html#inclusion)
* [length](https://guides.rubyonrails.org/active\_record\_validations.html#length)
* [numericality](https://guides.rubyonrails.org/active\_record\_validations.html#numericality)
* [presence](https://guides.rubyonrails.org/active\_record\_validations.html#presence)
* [absence](https://guides.rubyonrails.org/active\_record\_validations.html#absence)

[Common validation options](https://guides.rubyonrails.org/active\_record\_validations.html#common-validation-options) supported too.

**`subset` validation**

Because Active Entity supports array attribute, for some reason, you may want to test values of an array attribute are all included in a given set.

Active Entity provides `subset` validation to achieve that, it usage similar to `inclusion` or `exclusion`

```ruby
class Steak < ActiveEntity::Base
  attribute :side_dishes, :string, array: true, default: []
  validates :side_dishes, subset: { in: %w(chips mashed_potato salad) }
end
```

**`uniqueness_in_embeds` validation**

Active Entity provides `uniqueness_in_embeds` validation to test duplicate nesting virtual record.

Argument `key` is attribute name of nested model, it also supports multiple attributes by given an array.

```ruby
class Category < ActiveEntity::Base
  attribute :name, :string
end

class Reviewer < ActiveEntity::Base
  attribute :first_name, :string
  attribute :last_name, :string
end

class Book < ActiveEntity::Base
  embeds_many :categories
  validates :categories, uniqueness_in_embeds: {key: :name}

  embeds_many :reviewers
  validates :categories, uniqueness_in_embeds: {key: [:first_name, :last_name]}
end
```

**`uniqueness_in_active_record` validation**

Active Entity provides `uniqueness_in_active_record` validation to test given `scope` doesn't present in Active Record model.

The usage same as [uniqueness](https://guides.rubyonrails.org/active\_record\_validations.html#uniqueness) in addition you must give a AR model `class_name`

```ruby
class Candidate < ActiveEntity::Base
  attribute :name, :string

  validates :name,
            uniqueness_on_active_record: {
              class_name: "Staff"
            }
end
```



#### valid?

[https://github.com/jasl/activeentity/#validations](https://github.com/jasl/activeentity/#validations)

[https://github.com/adzap/validates\_timeliness](https://github.com/adzap/validates\_timeliness)
