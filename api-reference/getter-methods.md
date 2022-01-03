# Getter Methods

#### attribute\_names

Returns an Array of Strings containing the attributes on your All Futures model instance, as defined in your model class when you use the [`attribute`](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) method.

{% hint style="info" %}
`attribute_names` is also available as a class method.
{% endhint %}

#### attributes

Returns a Hash of the attributes on your All Futures model instance, as defined in your model class when you use the [`attribute`](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) method. You can pass this Hash to the `new` or `create` method of an Active Record model class.

The `attributes` Hash will not contain `id`, which is a property.

#### destroyed?

Returns `true` or `false`, depending on whether the current instance has been `destroy`ed.

#### id

`id` is a String that uniquely identifies an All Futures class instance. When combined with the name of your All Futures class, it is mapped directly to a Redis key. For example, if you have a `DraftPost` class with an id of `bdef228c-248c-4a50-abf0-6942353962bf`, your instance is stored in Redis as `DraftPost:bdef228c-248c-4a50-abf0-6942353962bf`.

#### new\_record?

Returns `true` if the current instance has not yet been saved to Redis.

#### persisted?

Returns `true` if the current instance is not a `new_record?` and has not been `destroyed?`.

#### previously\_new\_record?

Returns `true` if the current instance was a `new_record?` before it was saved to Redis. A record retrieved with `find` cannot have been "previously new".
