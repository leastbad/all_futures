# Class Methods

As powerful as Redis is, it is not a drop-in replacement for a relational database.

Methods like `all`, `find_by` and `where` all utilize Redis keyspace scanning, which is slow and thread-blocking. If you have a large number of records, use these methods with care - especially in production environments.

What is "large" in this context? It's impossible to say because every application is different, but we urge you to not build significant functionality that relies on keyspace scans.

You can use All Futures without any performance hit by tracking the `id` of the records that you are working with.

{% hint style="warning" %}
All Futures does not currently implement `ActiveRecord::Relation` or have a "scope" concept, although this functionality is planned for a future release.

Unlike Active Record models, class names are not Relations and are not composable. You cannot build a method chain or specify multiple `where` clauses, _yet_.

**If you are planning to do multiple operations that utilize the results of a keyspace scan, you are strongly advised to store the return value as there is no caching.**
{% endhint %}

#### all

#### any?

Returns `true` or `false` depending on whether there are any records in the Redis keyspace for this model. This will trigger a keyspace scan, so you might be better off using `all` or `where` and testing the Array returned with `any?` instead of using this method.

#### attribute\_names

Returns an Array of Strings containing the attributes on your All Futures model instance, as defined in your model class when you use the [`attribute`](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) method.

{% hint style="info" %}
`attribute_names` is also available as an instance getter method.
{% endhint %}

#### create(attributes = {})

#### exists?(arg)

Returns `true` or `false` depending on whether a record has been persisted to Redis. Typically, this is used by passing an `id`.

If a Hash or Array is passed, it is passed to the `where` method, then `any?` on the Array that is returned. This will trigger a keyspace scan.

If you pass `false`, it will return `false`. Finally, if you pass nothing, it calls `any?`.

#### find(id), find(id1, id2), find(\[id1, id2])

#### find\_by

#### new(attributes = {})

#### where

If you specify an attribute that is not present on the model, it will raise an `ActiveModel::UnknownAttributeError` exception.
