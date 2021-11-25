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

You will find methods for interrogating the values for each attribute at every stage, as well as tools for rolling back to previous versions. There are also methods which direct AllFutures to forget that changes happened at all.

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

When you see an attribute that contains the upper-case word `ATTR`, this means that there is a separate version of the method available for every attribute defined on your model.

Generally, you use the generic version eg. `attribute_will_change?(:name)` when you are going to iterate over your `attributes` Hash, while you use the specific version eg. `name_will_change?` when you are writing custom business rules.

#### rollback\_attributes(Array = changed), rollback\_attributes!(Array = changed)

#### rollback\_attribute(attribute), rollback\_attribute!(attribute)

#### restore\_attributes(Array = changed)

#### restore\_attribute(attribute)

#### clear\_changes\_information

#### changes\_applied

#### dirty?

#### changes

#### changed

#### changed\_attributes

#### previous\_changes

#### saved\_changes, saved\_changes?

#### clear\_attribute\_change(attribute), clear\_attribute\_changes(Array)

#### attribute\_will\_change?(attribute)

#### attribute\_present?(attribute)

#### attribute\_previously\_changed?(attribute)

#### attribute\_previously\_was(attribute)

#### attribute\_was(attribute)

#### attribute\_will\_change!(attribute), attribute\_will\_change?(attribute)

#### attribute\_changed?(attribute)

#### saved\_change\_to\_attribute(attribute), saved\_change\_to\_attribute?(attribute)

#### rollback\_attribute(attribute), rollback\_attribute!(attribute)

#### ATTR?

#### restore\_ATTR!

#### ATTR\_previous\_change

#### ATTR\_previously\_changed?

#### ATTR\_previously\_was

#### ATTR\_was

#### ATTR\_change, ATTR\_changed?

#### ATTR\_will\_change!, ATTR\_will\_change?

#### clear\_ATTR\_change

#### saved\_change\_to\_ATTR, saved\_change\_to\_ATTR?

#### rollback\_ATTR, rollback\_ATTR!
