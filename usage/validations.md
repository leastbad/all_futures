# Validations

One of the original Rails features that drew many to the framework was its powerful business rule validation system for Active Record. Controller actions that call `save` and use the return value to drive application behaviour are an enduring part of what makes Rails...Rails.

However, there is some rigidity in the approach Rails uses to test for model validity that frustrate the implementation of reactive applications. Even though Active Model has support for [form-level error messages](https://guides.rubyonrails.org/active\_record\_validations.html#errors-base), the standard request-based approach provided by Action Dispatch makes no distinction between field-level and form-level business rules. It's assumed that validation occurs when a form has been completed and the user submits it by clicking a button, 2004 style.

Let's say that you want to incrementally build a model by pushing updates every time the user changes a form input value. Perhaps you don't even have a traditional "submit" button! If your Active Record model has multiple mandatory attributes, it's not currently possible to do reactive validation on a per-attribute basis. Pushing an interim update to Mandatory Attribute A would immediately raise a presence validation error from Mandatory Attribute B.

AllFutures makes incremental model creation and validation easy.

### Validations 101

Active Record models cannot be saved unless they are in a valid state. `save` operations (including methods like `update`) call `valid?` and if any validations fail, then `save` returns `false`. `ActiveModel::Error` objects are added to the `errors` collection of the model.

What's interesting about the Active Record's design is that `valid?` is not just some getter that queries an internal state variable; it's actually the method that performs the validations process! If you inspect your model instance before `valid?` is called, you'll notice that the `errors` collection will be empty even if the model has values that would fail validation.

**AllFutures does not call `valid?` before saving.** Instead, `valid?` is a tool that you can call _when you need it_, and it is not tied to the persistance layer in any way. :zap:

{% hint style="success" %}
`validate` is aliased to `valid?` and might be grammatically satisfying in some contexts.
{% endhint %}

### Implementing validations

The AllFutures validations are really just [Active Entity validations](https://github.com/jasl/activeentity/#validations), which means that [Jun Jiang](https://twitter.com/jasl9187) did all of the hard work. I am including a slightly edited copy of his instructions here for convenience.

{% hint style="success" %}
AllFutures (and Active Entity) support many 3rd-party Active Model extensions, such as [adzap/validates\_timeliness](https://github.com/adzap/validates\_timeliness).
{% endhint %}

Defining AllFutures validations works just like it does in an Active Record model:

```ruby
class Book < AllFutures::Base
  attribute :title, :string
  validates :title, presence: true
end
```

Many Active Record validations are directly supported:

* [acceptance](https://guides.rubyonrails.org/active\_record\_validations.html#acceptance)
* [confirmation](https://guides.rubyonrails.org/active\_record\_validations.html#confirmation)
* [exclusion](https://guides.rubyonrails.org/active\_record\_validations.html#exclusion)
* [format](https://guides.rubyonrails.org/active\_record\_validations.html#format)
* [inclusion](https://guides.rubyonrails.org/active\_record\_validations.html#inclusion)
* [length](https://guides.rubyonrails.org/active\_record\_validations.html#length)
* [numericality](https://guides.rubyonrails.org/active\_record\_validations.html#numericality)
* [presence](https://guides.rubyonrails.org/active\_record\_validations.html#presence)
* [absence](https://guides.rubyonrails.org/active\_record\_validations.html#absence)

Validation options are supported too:

* [allow\_nil](https://guides.rubyonrails.org/active\_record\_validations.html#allow-nil)
* [allow\_blank](https://guides.rubyonrails.org/active\_record\_validations.html#allow-blank)
* [message](https://guides.rubyonrails.org/active\_record\_validations.html#message)
* [on](https://guides.rubyonrails.org/active\_record\_validations.html#on)

You can use [strict mode](https://guides.rubyonrails.org/active\_record\_validations.html#strict-validations), which causes raises an `ActiveModel::StrictValidationFailed` exception if you attempt to `validate` a model with \[failing] strict validations:

```ruby
validates :title, presence: {strict: true}
```

You can also include your own [custom validator classes](https://guides.rubyonrails.org/active\_record\_validations.html#custom-validators), and call [custom validator methods](https://guides.rubyonrails.org/active\_record\_validations.html#custom-methods) with the `validates` method.

### AllFutures validations

AllFutures also provides several validator methods, courtesy of Active Entity:

**`subset` validation**

AllFutures supports array attributes, so you may want to ensure that the elements of an array attribute are included in a given set.

The `subset` validation has syntax similar to `inclusion` or `exclusion`:

```ruby
class Steak < AllFutures::Base
  attribute :side_dishes, :string, array: true, default: []
  validates :side_dishes, subset: { in: %w(chips mashed_potato salad) }
end
```

**`uniqueness_in_embeds` validation**

The `uniqueness_in_embeds` validation ensures that you have only unique virtual records when working with embedded (nested) models.

`key` is the attribute name of the nested model. Test multiple attributes by passing an Array.

```ruby
class Category < AllFutures::Base
  attribute :name, :string
end

class Reviewer < AllFutures::Base
  attribute :first_name, :string
  attribute :last_name, :string
end

class Book < AllFutures::Base
  embeds_many :categories
  validates :categories, uniqueness_in_embeds: {key: :name}

  embeds_many :reviewers
  validates :categories, uniqueness_in_embeds: {key: [:first_name, :last_name]}
end
```

**`uniqueness_in_active_record` validation**

The `uniqueness_in_active_record` validation is AllFutures' answer to Active Record's [uniqueness](https://guides.rubyonrails.org/active\_record\_validations.html#uniqueness) validation. It will perform a query against a `scope` to ensure that the attribute value is not already present in your relational datastore.

In addition to the standard `uniqueness` options, you are required to specify an Active Record model `class_name` for it to perform the query.

```ruby
class Candidate < AllFutures::Base
  attribute :name, :string

  validates :name,
            uniqueness_on_active_record: {
              class_name: "Staff"
            }
end
```

### Conditional validations

The only way to implement incremental validations with vanilla Active Record is to use its powerful conditional validation mechanisms. Historically, this has been the only way to build "wizard" style UIs. Use `:if` or `:unless` to evaluate a function that decides if the validation is applied.

You can [pass a Symbol](https://guides.rubyonrails.org/active\_record\_validations.html#using-a-symbol-with-if-and-unless) to call a method, or [provide a Lambda](https://guides.rubyonrails.org/active\_record\_validations.html#using-a-proc-with-if-and-unless) to evaluate in-line:

```ruby
class Order < AllFutures::Base
  validates :password, confirmation: true, unless: -> { password.blank? }
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

It's possible to define [groups of validations](validations.md#validations-101) that are only applied if a condition is met e.g. if the `is_author` Boolean attribute is `true`:

```ruby
class DraftPost < AllFutures::Base
  with_options if: :is_author? do
    validates :title, presence: true
    validates :body, length: { minimum: 10 }
  end
end

```

You can even construct unholy mashups of all these techniques, using `:if` and `:unless` [in combination](https://guides.rubyonrails.org/active\_record\_validations.html#combining-validation-conditions). There's a "great" example in the Rails Guide:

```ruby
class Computer < ApplicationRecord
  validates :mouse, presence: true,
                    if: [Proc.new { |c| c.market.retail? }, :desktop?],
                    unless: Proc.new { |c| c.trackpad.present? }
end

```

Unfortunately, the code required to use conditional validation logic in a complex scenario quickly becomes **brittle** and **difficult to maintain**. AllFutures _supports_ Active Record's conditional mechanisms for compatibility, but you are strongly encouraged to consider a new approach...

### The AllFutures way

Cooking shows would be really boring (and short) if all of the recipes were ready to go into the oven at the beginning of the episode. We trust that the ultimate application of heat will be successful, but watch the chef because the important parts are all in the middle.

Active Record wants fully assembled dishes that are ready to go into the oven. AllFutures is all about how you slice the onions and blend the sauces.

{% embed url="https://www.youtube.com/watch?v=HgG_b9L7dwo" %}
I'm not really familiar with mustard in my Russian
{% endembed %}

The key design difference that sets AllFutures apart from Active Record is that a model instance does not have to be valid to be persisted to Redis.

This means that it's perfectly okay for you to work iteratively, tweaking attributes and providing an infrastructure upon which a reactive UI can be quickly built.

**AllFutures sits in front of Active Record like a firewall, meaning that it can remove much of the complexity that led to conditional validations in the first place.**

While you should still have validations in place to ensure the integrity of your Active Record model, having AllFutures in your pipeline means that you'll be passing data to Active Record that's already valid, outside of \[literally] exceptional cases.

You will reduce the overall complexity of your Active Record model classes, which can now focus on persistence, while delegating the workflow of your business objects to AllFutures.

How cool is that?

When AllFutures is in the kitchen, conditional Active Record validations can go in the compost.

### Programmatic validations

AllFutures adds the ability to see if a single given attribute is currently valid. **This is exceptionally useful for building reactive interfaces.** :bulb:

Note that any errors on the `:base` have no impact individual attribute validity.

#### attribute\_valid?(attribute), ATTR\_valid?

Just like calling `valid?`, but for one attribute. Returns `true` if the specified attribute passes all validation helpers.

```ruby
post_draft.attribute_valid? :name
post_draft.name_valid?
```

#### Meta-programming validations

You can introspect the validations on a model with the `validators` class method, which returns a Hash that is keyed to the attributes. Get an Array of validation objects for the `name` attribute with `validators_on` class method.

```ruby
PostDraft.validators
PostDraft.validators_on :name
```

### Sharing validations with Active Record

Hopefully, it's self-evident that defining the same validations on both AllFutures and Active Record models would be repetitive today and a maintenance burden tomorrow. Instead, create a Concern that you can include in both models.

Let's create a `Postable` Concern that we can use in our `Post` Active Record model and our `PostDraft` AllFutures model:

{% code title="app/models/concerns/postable.rb" %}
```ruby
module Postable
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
  end
end
```
{% endcode %}

Now you can just include `Postable` in both models:

```ruby
class Post < ApplicationModel
  include Postable
end

class PostDraft < AllFutures::Base
  include Postable
end
```

If you have any validations that are only intended to run in one of the models, you can just keep it in the appropriate class. However, there's also another technique that could be helpful in advanced scenarios: you can selectively include class method calls based on the class of the object that is calling it.

```ruby
module Postable
  extend ActiveSupport::Concern

  included do |base|
    validates :name, presence: true
    if base < ActiveRecord::Base
      validates :name, uniqueness: true
    end
  end
end
```
