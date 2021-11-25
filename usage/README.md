# Usage

Working with AllFutures is intentionally very similar to working with ActiveRecord, and most of the same methods will work. You will create a class and define the scopes, validations, callbacks and instance methods you need.

AllFutures models persist to Redis instead of your relational database. Place AllFutures classes in `app/models`, alongside your ActiveRecord models.

### Hello World

For this example, we'll use [StimulusReflex](https://stimulusreflex.com) to send updates to the server when the user enters data into either of two text input elements.

The most visible difference between an ActiveRecord model and an AllFutures model is that instead of migrations and a schema, you need to declare your [attributes](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) in the class:

{% code title="app/models/example.rb" %}
```ruby
class Example < AllFutures::Base
  attribute :name, :string
  attribute :age, :integer, default: 21
end
```
{% endcode %}

Let's use our new `Example` model to respond to a page request.

First, create an instance and assign it to an instance variable in the controller action:

{% code title="app/controllers/example_controller.rb" %}
```ruby
class ExampleController < ApplicationController
  def index
    @example = Example.create
  end
end
```
{% endcode %}

Emit the instance id as a data attribute on every element which can update your model.

```
Name: <input type="text" data-id="<%= @example.id %>" data-reflex="input->Example#name" /><br/>
Age: <input type="text" data-id="<%= @example.id %>" data-reflex="input->Example#age" />
```

Since all attributes are gathered and sent to the server during a Reflex operation, it's easy to retrieve the instance id from the Reflex element accessor and use it to `find` the correct AllFutures object and make changes to it.

The following methods both find a record and update it, using StimulusReflex:

{% code title="app/reflexes/example_reflex.rb" %}
```ruby
class ExampleReflex < ApplicationReflex
  def name
    example = Example.find(element.dataset.id)
    example.name = element.value
    example.save
  end

  def age
    Example.find(element.dataset.id).update age: element.value
  end
end
```
{% endcode %}

You can now update your instance across multiple calls or requests, regardless of whether the user refreshes or navigates away from the page. So long as you have the `id` of the instance you need, you can access it until your Redis cache expiry policy purges it at some point in the distant future.

{% hint style="danger" %}
AllFutures v1 persisted the attributes every time you set the value of an attribute using bracket notation. **This behavior has been removed.** An explicit `save` operation is now required to persist changes.
{% endhint %}

### Class methods

There are two ways to create an AllFutures class instance: `new` and `create`. Both methods accept an optional Hash of attributes:

```ruby
Example.new # no values set, and not yet persisted
Example.new name: "Steve" # not yet persisted
example = Example.new name: "Steve"
example.save # now it's persisted
puts example.id # you'll need the id to access this instance later

Example.create # no values set; persisted but no way to access the id
example_id = Example.create(name: "Bob").id # winning
```

Retrieving an instance later just requires passing an `id` to the `find` method:

```ruby
example = Example.find(example_id)
```

{% hint style="success" %}
In AllFutures, `id` is a property, not an attribute. It's not treated as data.
{% endhint %}

### CRUD instance methods

These are the methods you'll use most frequently. You can pass attributes parameters using either String or Symbol form.

#### save, save!

A true classic - accept no substitutes! `save` will persist the current state of the attributes and inform the dirty checking mechanism that changes are now past-tense.

Both methods return `true` if the operation is successful. If unsuccessful, `save` will return `false` while `save!` will raise an `ActiveRecord::RecordNotSaved` exception.

#### update(attributes = {}), update!(attributes = {})

This should be familiar to ActiveRecord users, as it accepts a Hash of attributes to persist. Internally, the `save` method will not be called unless there are changes to at least one attribute. If you attempt to pass an invalid attribute, it will raise an `ActiveModel::UnknownAttributeError` exception.

Both methods return `true` if the operation is successful. If unsuccessful, `update` will return `false` while `update!` will raise an `ActiveRecord::RecordNotSaved` exception.

#### destroy, destroy!, delete

`destroy` will attempt to remove the current instance from Redis and mark the instance as destroyed, which prevents further attempts to `save`.

All three methods return the `attributes` Hash when successful.

`destroy!` functions the same way as `destroy`, except that it will raise a `RecordNotDestroyed` exception if no data was deleted.

`delete` will remove the record even if the `readonly?` method returns `true`. The `before_destroy` and `after_destroy` callbacks are not called.

### Additional instance methods

{% hint style="success" %}
`attributes` can be passed in Symbol or String form.
{% endhint %}

#### ==(comparison\_object)

Returns `true` if `comparison_object` is the same exact AllFutures model instance **or** `comparison_object` is of the same type and has the same `id`.

Note also that destroying a record preserves its ID in the model instance, so deleted models are still comparable.

#### assign\_attributes(Hash)

Update the current value of one or several attributes without committing them to Redis.

#### attribute\_present?(attribute)

Returns `true` if the specified attribute has been set by the user or by a Redis load and is neither `nil` nor `empty?` (the latter only applies to objects that respond to `empty?`, most notably Strings). Otherwise, `false`.

Note that it always returns `true` with Boolean attributes.

#### becomes(ActiveRecord::Base)

Returns an instance of the specified class with the attributes and state of the current record. In addition to attributes, the `changed_attributes`, `new_record?` and `destroyed?` values as well as the `errors` collections are cloned. `id` is **not** transferred.

{% hint style="success" %}
In many cases, it is sufficient to simply pass the `attributes` Hash to the `new` or `create` method of the ActiveRecord model class that you want to create.
{% endhint %}

#### decrement(attribute, by = 1), decrement!(attribute, by = 1), increment(attribute, by = 1), increment!(attribute, by = 1)

Increase or decrease an Integer attribute by 1, or any number you provide as an optional second parameter. `decrement` and `increment` work without writing to Redis, while `decrement!` and `increment!` both commit all outstanding changes.

#### freeze, frozen?

Freeze the attributes hash such that associations are still accessible, even on destroyed records. Cloned models will not be frozen.

#### has\_attribute?(attribute)

Returns `true` or `false` depending on whether `attribute` has been defined in your model.

#### id=(String)

`id` is a String that uniquely identifies an AllFutures class instance. If you do not set an `id` before your instance is saved, it will be assigned a unique UUIDv4 code.

If you assign an Integer or other value to `id`, it will be converted to a String.

{% hint style="info" %}
You cannot change the primary key AllFutures uses to be something other than `id`.

Once the instance has been saved, the `id` is permanent. Attempts to change it will raise a `FrozenError`.
{% endhint %}

#### reload

This will update all attributes with the current data from Redis and resets the dirty checking mechanism. Only attributes that are divergent from Redis are touched. It will return the model instance.

{% hint style="info" %}
Unfortunately, it's not currently possible for an AllFutures instance to track changes in Redis that are made after the attributes are loaded. While [I have written about how this problem could be solved](https://dev.to/leastbad/async-redis-key-mutation-notifications-in-rails-4hng) with Redis pubsub, it really seemed as though people didn't understand why this would be useful. If you are equally excited about a **reactive** AllFutures in the future, please let me know on [Discord](https://discord.gg/stimulus-reflex).
{% endhint %}

#### slice(\*methods)

Returns a Hash of the given methods with their names as keys and returned values as values.

```ruby
example = Example.new page: 3
example.slice :id, :page, :to_partial_path
# {"id"=>nil, "page"=>3, "to_partial_path"=>"examples/example"}
```

#### toggle(attribute), toggle!(attribute)

Flip the value of a Boolean attribute to the opposite of its current value. `toggle` changes the attribute but does not persist, and returns the model instance. `toggle!` changes the attribute and saves the instance, returning `true` or `false` based on the success of the operation.

#### to\_json

Returns the `attributes` as a JSON-serialized String.

#### update\_attribute(attribute, value)

Use this method to programmatically update attributes. No callbacks will be executed. Attributes must exist and not be marked `readonly` to be updated. Returns `true` or `false` depending on the success of the operation.

### Properties

#### attribute\_names

`attribute_names` returns an Array of Strings containing the attributes on your AllFutures model instance, as defined in your model class when you use the [`attribute`](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) method.

#### attributes

`attributes` returns a Hash of the attributes on your AllFutures model instance, as defined in your model class when you use the [`attribute`](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) method. You can pass this Hash to the `new` or `create` method of an ActiveRecord model class.

The `attributes` Hash will not contain `id`, which is a property.

#### destroyed?

Returns `true` or `false`, depending on whether the current instance has been `destroy`ed.

#### id

`id` is a String that uniquely identifies an AllFutures class instance. When combined with the name of your AllFutures class, it is mapped directly to a Redis key. For example, if you have a `DraftPost` class with an id of `bdef228c-248c-4a50-abf0-6942353962bf`, your instance is stored in Redis as `DraftPost:bdef228c-248c-4a50-abf0-6942353962bf`.

#### new\_record?

Returns `true` if the current instance has not yet been saved to Redis.

#### persisted?

Returns `true` if the current instance is not a `new_record?` and has not been `destroyed?`.

#### previously\_new\_record?

Returns `true` if the current instance was a `new_record?` before it was saved to Redis. A record retrieved with `find` cannot have been "previously new".

### Methods to overwrite

These methods are already defined on your AllFutures class. 90% of the time, these defaults are great. If you have complex needs, you can redefine them with your own logic.

#### to\_key

If you attempt to sort two objects of the same class, Ruby will call the `to_key` method and use the Array it returns to sort. By default, the `to_key` Array contains the `id`. Since AllFutures models frequently have a UUIDv4 `id`, this isn't a useful sorting criteria.

You can specify one or more attributes - or other values - to sort by instead.

```ruby
def to_key
  [name, age, id]
end
```

#### to\_param

Returns a String representing the model's key suitable for use in URLs, or `nil` if `persisted?` is `false`. The key is usually the `id`, but this can be overwritten to provide vanity URL slugs.

```ruby
def to_param
  "#{id}-#{title}"
end
```

#### to\_partial\_path

ActiveRecord model instances can be passed to Rails' `render` method, and if ActionPack can locate a partial in the correct location based on that model, it will render that partial. `to_partial_path` is responsible for this magic.

AllFutures models can also be passed to `render`. If you have a `Drafts` model, `to_partial_path` returns `drafts/draft` and ActionPack will look for `app/views/drafts/_draft.html.erb`. If this isn't where the partial for your model is located, define your own:

```ruby
def to_partial_path
  "article_drafts/preview"
end
```

ActionPack will now attempt to render `app/views/article_drafts/_preview.html.erb`.

#### readonly?

Query `readonly?` to see if this model instance has been marked as `readonly`, which prevents all `save`, `update` and `destroy` operations.

Want to ensure that no changes are written to Redis for this model class, ever?

```ruby
def readonly?
  true
end
```
