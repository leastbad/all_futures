# Instance Methods

{% hint style="success" %}
`attribute` name parameters can be passed as a Symbol or String.
{% endhint %}

#### ==(comparison\_object)

Returns `true` if `comparison_object` is the same exact All Futures model instance **or** `comparison_object` is of the same type and has the same `id`.

Note also that destroying a record preserves its `id` in the model instance, so deleted models are still comparable.

#### assign\_attributes(Hash)

Update the current value of one or several attributes without committing them to Redis.

#### attribute\_present?(attribute)

Returns `true` if the specified attribute has been set by the user or by a Redis load and is neither `nil` nor `empty?` (the latter only applies to objects that respond to `empty?`, most notably Strings). Otherwise, `false`.

Note that it always returns `true` with Boolean attributes.

#### attribute\_valid?(attribute), ATTR\_valid?

Just like calling `valid?`, but for one attribute. Returns `true` if the specified attribute passes all validation helpers.

Also available as a dynamic method (created for every attribute in your model).

#### decrement(attribute, by = 1), decrement!(attribute, by = 1), increment(attribute, by = 1), increment!(attribute, by = 1)

Increase or decrease an Integer attribute by 1, or any number you provide as an optional second parameter. `decrement` and `increment` work without writing to Redis, while `decrement!` and `increment!` both commit all outstanding changes.

#### destroy, destroy!, delete

`destroy` will attempt to remove the current instance from Redis and mark the instance as destroyed, which prevents further attempts to `save`.

All three methods return the `attributes` Hash when successful.

`destroy!` functions the same way as `destroy`, except that it will raise a `RecordNotDestroyed` exception if no data was deleted.

`delete` will remove the record even if the `readonly?` method returns `true`. The `before_destroy` and `after_destroy` callbacks are not called.

#### freeze, frozen?

Freeze the attributes hash such that associations are still accessible, even on destroyed records. Cloned models will not be frozen.

#### has\_attribute?(attribute)

Returns `true` or `false` depending on whether `attribute` has been defined in your model.

#### id=(String)

`id` is a String that uniquely identifies an All Futures class instance. If you do not set an `id` before your instance is saved, it will be assigned a unique UUIDv4 code.

If you assign an Integer or other value to `id`, it will be converted to a String.

{% hint style="info" %}
You cannot change the primary key All Futures uses to be something other than `id`.

Once the instance has been saved, the `id` is permanent. Attempts to change it will raise a `FrozenError`.
{% endhint %}

#### reload

This will refresh all attributes and previous attributes with the current data from Redis. It will return the model instance with the current values.

{% hint style="info" %}
Unfortunately, it's not currently possible for an All Futures instance to track changes in Redis that are made after the attributes are loaded. While [I have written about how this problem could be solved](https://dev.to/leastbad/async-redis-key-mutation-notifications-in-rails-4hng) with Redis pubsub, it really seemed as though people didn't understand why this would be useful. If you are equally excited about a **reactive** All Futures _in the future_, please let me know on [Discord](https://discord.gg/stimulus-reflex).
{% endhint %}

#### save, save!

A true classic - accept no substitutes! `save` will persist the current state of the attributes and inform the dirty checking mechanism that changes are now past-tense.

Both methods return `true` if the operation is successful. If unsuccessful, `save` will return `false` while `save!` will raise an `AllFutures::RecordNotSaved` exception.

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

#### update(attributes = {}), update!(attributes = {})

This should be familiar to Active Record users, as it accepts a Hash of attributes to persist. Internally, the `save` method will not be called unless there are changes to at least one attribute. If you attempt to pass an invalid attribute, it will raise an `AllFutures::InvalidAttribute` exception.

Both methods return `true` if the operation is successful. If unsuccessful, `update` will return `false` while `update!` will raise an `AllFutures::RecordNotSaved` exception.

#### update\_attribute(attribute, value)

Use this method to programmatically update attributes. No callbacks will be executed. Attributes must exist and not be marked `readonly` to be updated. Returns `true` or `false` depending on the success of the operation.
