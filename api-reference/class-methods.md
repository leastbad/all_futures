# Class Methods

As powerful as Redis is, it is not a drop-in replacement for a relational database.

Methods like `all`, `find_by` and `where` all utilize Redis keyspace scanning, which is slow and thread-blocking. If you have a large number of records, use these methods with care - especially in production environments.

What is "large" in this context? It's impossible to say because every application is different, but we urge you to not build significant functionality that relies on keyspace scans.

You can use All Futures without any performance hit by tracking the `id` of the records that you are working with.

{% hint style="warning" %}
All Futures does not currently implement `ActiveRecord::Relation` or have a "scope" concept, although this functionality _is_ planned for a future release.

Unlike Active Record models, class names are not Relations and are not composable. You cannot build a method chain or specify multiple `where` clauses, _yet_.

**If you are planning to do multiple operations that utilize the results of a keyspace scan, you are strongly advised to store the return value as there is no caching.**
{% endhint %}

#### all

Perform a keyspace scan and return an Array containing all records that have been created. Records are sorted in the order of their creation, oldest to newest.

#### any?(\&block)

Returns `true` or `false` depending on whether there are any records in the Redis keyspace for this model. This will trigger a keyspace scan, so you might be better off using `all` or `where` and testing the Array returned with `any?` instead of using this method.

If you pass a block, it will be evaluated for every record until one returns `true`.

#### attribute\_names

Returns an Array of Strings containing the attributes on your All Futures model instance, as defined in your model class when you use the [`attribute`](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) method.

{% hint style="info" %}
`attribute_names` is also available as an instance getter method.
{% endhint %}

#### create(attributes = {}, \&block)

Pass a Hash of attributes to create an instance of your All Futures model and persist it to Redis. Attributes need to be valid; that is, defined on your model using the `attribute` class method.

If you want to set an `id` for the instance, you will need to pass it in via the Hash; otherwise, a UUID will be assigned as the `id` automatically.

If you pass a block, it will be called after the record is initialized and before it is saved.

#### count

Return an Integer reporting the total number of records stored in Redis. A keyspace scan is required.

#### delete\_all

Deletes every record from Redis without creating instances in memory.

Callbacks will not be run. A keyspace scan is required.

#### delete\_by(attributes = {}, \&block)

Calls `where` and then deletes matching records. Models are instantiated.

Callbacks will not be run. A keyspace scan is required.

#### destroy\_all

`destroy` is called on every record, after models are instantiated.

Callbacks will be run. A keyspace scan is required.

#### destroy\_by(attributes = {}, \&block)

Calls `where` and then `destroy`s matching records. Models are instantiated.

Callbacks will be run. A keyspace scan is required.

#### exists?(arg)

Returns `true` or `false` depending on whether a record has been persisted to Redis. Typically, this is used by passing an `id`. This _will not_ trigger a keyspace scan.

If a Hash or Array is passed, it is passed to the `where` method, then `any?` on the Array that is returned. This _will_ trigger a keyspace scan.

If you pass `false`, it will return `false`. Finally, if you pass nothing, it calls `any?`.

#### find(id), find(id1, id2), find(\[id1, id2])

Retrieve one or more AllFutures model instances. If you pass one `id`, it will return the model instance.

If you pass either a list of `id`s or an Array of `id`s, you will receive an Array of model instances.

Regardless of how many `id`s that you pass into `find`, all of them must be available or an `AllFutures::RecordNotFound` exception will be raised.

#### find\_by(attributes = {})

Perform a `where` operation (which might require a keyspace scan, depending on what you pass) and return either the first record with attributes that match, or `nil`.

#### find\_by!(attributes = {})

Perform a `where` operation (which might require a keyspace scan, depending on what you pass) and return either the first record with attributes that match or raise an `AllFutures::RecordNotFound` exception.

#### find\_or\_create\_by(attributes = {}, \&block)

Perform a `find_by` operation (which might require a keyspace scan, depending on what you pass) and if a record is not retrieved, `create` a new record with the attributes you specified.

If you pass a block and a new record is created, the block will be called after the record is initialized and before it is saved.

#### find\_or\_initialize\_by(attributes = {}, \&block)

Perform a `find_by` operation (which might require a keyspace scan, depending on what you pass) and if a record is not retrieved, initialize a `new` record with the attributes you specified.

If you pass a block and a new record is initialized, the block will be called at the end of the initialization process.

#### ids

Returns an array containing the key of every record saved to Redis. This requires a keyspace scan, which will slow down the server when there's a large number of records.

#### new(attributes = {}, \&block)

Pass a Hash of attributes to initialize an instance of your All Futures model that has not been persisted to Redis. Attributes need to be valid; that is, defined on your model using the `attribute` class method.

Optionally, you may pass an `id` in the Hash, alongside the attributes.

If you pass a block, it will be called at the end of the initialization process.

#### valid\_attribute?(attribute)

Return `true` or `false` depending on whether the `attribute` provided is either `id` or a valid attribute that has been defined in your All Futures class.

#### where(attributes = {}, \&block)

Perform a keyspace scan and return an Array containing the records which match the attributes provided. This is an all-or-nothing comparison; records must match all attributes specified.

```ruby
Example.where name: "Steve"
```

String and Array parameters are not supported at this time; however, in a departure from the `where` method in Active Record, the All Futures `where` method does accept an optional block which will be evaluated in addition to any attribute comparisons.

```ruby
Example.where do |record|
  record.name.starts_with? "S"
end
```

You can combine attribute and block queries:

```ruby
Example.where name: "Steve" do |record|
  record.email.include? "@"
end
```

If no records match, `where` will return an empty Array.

{% hint style="warning" %}
Remember, `where` returns an Array, not an `ActiveRecord::Relation`. You can chain the usual `Enumerable` methods, but you cannot specify complex queries use scopes at this time.
{% endhint %}

If you specify an attribute that is not present on the model, it will raise an `AllFutures::InvalidAttribute` exception.
