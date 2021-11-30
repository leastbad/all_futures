---
description: Attribute and object level dirty checking with rollback support
---

# Dirty

This is an area of functionality that you might not ever need. If you do need it, you will be endlessly thankful that it is here.

> You can't go back and change the beginning, but you can start where you are and change the ending.
>
> C.S. Lewis

AllFutures provides an obsessively complete API for inspecting, manipulating and reversing changes to your model's attributes.

If history is written by the winner, there are three high-level concepts that you need to :bulb: so that you can win:

1. 3-stage timeline: previously, was and \[future] changes
2. Changes are tracked, but you can mess with the tapes
3. Single-attribute and record-level methods are available

### Timeline

Imagine that you create a new instance of your `Example` model:

```ruby
class Example < AllFutures::Base
  attribute :name, :string
  attribute :age, :integer, default: 21
end

example = Example.new
puts example.name # => nil
puts example.age  # => 21
```

Now, we're going to change the `name` to "Steve", `save` it, and then change the `name` to "Fred".

```ruby
puts example.name        # Previously nil
example.name = "Steve"
example.save
puts example.name        # Was Steve
example.name = "Fred"
puts example.name        # Changed to Fred
```

AllFutures is able to keep track of the **previous** value before an attribute was saved, the value it became when it **was** saved, and the value it **changed** to after it was saved. Only the most recent current value is stored, and if nothing changes, it's possible two or all three \[of the previous/was/changed] values could be the same.

### Tracking

Internally, the `changes_applied` method is called when the current state of the attributes is saved to Redis. This is done for you with the standard CRUD methods like `save` and `update`.

You will find methods for interrogating the values for each attribute at every stage, as well as tools for rolling back to previous versions. **There are also methods which direct AllFutures to forget that changes happened at all.**

### Forest or Trees

It might seem like there's a lot of methods in this module, but for maximum developer silkiness there are often several methods per concept. Take the _fictional_ method `pound`:

* pound :name
* pound! :name
* pound\_all
* pound\_all!
* pound\_name
* pound\_name!

As you see, we have generic methods, collection methods and dynamic methods. The convention is that **if it ends with a `!`, it gets saved to Redis**.

### Instance methods

Generally, you use the generic version eg. `attribute_will_change?(:name)` when you are going to iterate over your `attributes` Hash, while you use the specific version eg. `name_will_change?` when you are writing custom business rules.

#### attribute\_change(attribute), attribute\_changed?(attribute)

If `attribute` has changed since the last `save`, returns an Array where the first element is the saved value and the second element is the value it will change to if saved. Otherwise, returns `nil`.

`?` form interrogates dirty tracking for `attribute` and returns `true` or `false`.

#### attribute\_present?(attribute)

Returns `true` if the specified attribute exists and has been set by the user and is neither `nil` nor `empty?` (the latter only applies to objects that respond to `empty?`, most notably Strings). Otherwise, it returns `false`. Note that it always returns `true` with Boolean attributes.

#### attribute\_previous\_change(attribute), attribute\_previously\_changed?(attribute)

Returns an Array where the first element is the value of the `attribute` before it was saved, and the second element is the value after it was saved.

`?` form returns `true` or `false` depending on whether `attribute` was changed to a new value at the time of the last `save` operation.

#### attribute\_previously\_was(attribute)

Returns the value of `attribute` **before** the last `save` operation.

#### attribute\_was(attribute)

Returns the value of `attribute` **after** the last `save` operation, before it was changed.

#### attribute\_will\_change!(attribute), attribute\_will\_change?(attribute)

Forces dirty tracking to report that the value of `attribute` has changed, even if it has not. `?` form is an alias for `attribute_changed?`

#### changed

Returns an Array of Strings, showing all attributes that have changed **after** the most recent `save` operation.

#### changed\_attributes, changed\_attributes?

Returns a Hash of all changes **after** the most recent `save` operation, where the key is the attribute name as a String, and the value is the **former** value, which the attribute was changed from.

For example, if you change the `search` attribute from `nil` to `"foo"` and call `changed_attributes`, it will return `{"search"=>nil}`

`changed_attributes?` is an alias for `dirty?`

#### changes

Returns a Hash of all changes **after** the most recent `save` operation, where the attribute is the String key and the value is is an Array containing the value before and the value after it was saved.

For example, if you change the `search` attribute from `nil` to `"foo"` and call `changes`, it will return `{"search"=>[nil, "foo"]}`

#### changes\_applied

Clears dirty data and moves changes to previous changes.

#### clear\_attribute\_change(attribute), clear\_attribute\_changes(Array)

Remove dirty tracking data for an attribute or an Array of attributes, without modifying the value itself. This has the effect of fooling AllFutures into forgetting that data was changed.

Singluar form returns `nil` while plural form returns an Array of attributes that had their dirty tracking data removed.

#### clear\_changes\_information

Clears all dirty data: current changes and previous changes.

#### dirty?

Reports `true` or `false` depending on whether there any attributes with data that have changed since the last `save` operation.

#### previous\_changes, previous\_changes?

Returns a Hash of all changes that were persisted with the most recent `save` operation, where the key is the name of the attribute in String form and the value is is an Array containing the value before and the value after it was saved.

For example, if you change the `search` attribute from `nil` to `"foo"`, call `save` and then `previous_changes`, it will return `{"search"=>[nil, "foo"]}`

`previous_changes?` is an alias for `saved_changes?`

#### restore\_attribute(attribute)

Change an `attribute` to the value it was **after** the last `save` operation. It will return an Array of Symbols for the attributes that were restored.

#### restore\_attributes(Array = changed)

Change attributes to the value that they were **after** the last `save` operation. You can either specify an Array of attributes to restore or it will default to all of the attributes with values that have changed since the last `save` operation. It will return an Array of Symbols for the attributes that were restored.

#### rollback\_attribute(attribute), rollback\_attribute!(attribute)

Change an `attribute` to the value it was **before** the last `save` operation. It will return the restored value that the attribute was returned to.

If you use the `!` version, it will `save` after rolling back the value, and return `true` or `false`.

#### rollback\_attributes(Array = changed), rollback\_attributes!(Array = changed)

Change attributes to the value that they were **before** the last `save` operation. You can either specify an Array of attributes to rollback, or it will default to all of the attributes with values that have changed since the last `save` operation. It will return an Array of Symbols for the attributes that were rolled back.

If you use the `!` version, it will `save` after rolling back the values, and return `true` or `false`.

#### saved\_changes, saved\_changes?

Returns a Hash of all changes **after** the most recent `save` operation, where the key is the attribute name as a String, and the value is the **new** value, which the attribute was changed to.

For example, if you change the `search` attribute from `nil` to `"foo"` and call `saved_changes`, it will return `{"search"=>"foo"}`

`saved_changes?` returns `true` or `false` depending on whether any attribute value changes have been persisted with a `save` call.

### Per-attribute instance methods

When you see an attribute that contains the upper-case word `ATTR`, this means that there is a separate version of the method available for every attribute defined on your model.

For example, if you have a `search` attribute, you will have methods such as `search_will_change?` and `rollback_search!` available.

#### ATTR?

Returns `true` or `false` depending on standard Ruby evaluation of attribute value. This is most useful for Boolean type attributes.

#### ATTR\_change, ATTR\_changed?

Attribute method version of `attribute_change` and `attribute_changed?`

#### ATTR\_previous\_change, ATTR\_previously\_changed?

Attribute method versions of `attribute_previous_change` and `attribute_previously_changed?`

#### ATTR\_previously\_was

Attribute method version of `attribute_previously_was`

#### ATTR\_was

Attribute method version of `attribute_was`

#### ATTR\_will\_change!, ATTR\_will\_change?

Attribute method version of `attribute_will_change!` and `attribute_will_change?`

#### clear\_ATTR\_change

Attribute method version of `clear_attribute_change`

#### restore\_ATTR

Attribute method version of `restore_attribute`

#### rollback\_ATTR, rollback\_ATTR!

Attribute method version of `rollback_attribute` and `rollback_attribute!`
