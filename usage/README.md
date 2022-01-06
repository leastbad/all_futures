# Usage

Working with All Futures is intentionally very similar to working with Active Record, and most of the same methods will work. You will create a class and define the scopes, validations, callbacks and instance methods you need.

All Futures models persist to Redis instead of your relational database. Place All Futures classes in `app/models`, alongside your Active Record models.

### Hello World

For this example, we'll use [StimulusReflex](https://stimulusreflex.com) to send updates to the server when the user enters data into either of two text input elements.

The most visible difference between an Active Record model and an All Futures model is that instead of migrations and a schema, you need to declare your [attributes](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute) in the class:

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

Since all attributes are gathered and sent to the server during a Reflex operation, it's easy to retrieve the instance id from the Reflex element accessor and use it to `find` the correct All Futures object and make changes to it.

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
All Futures v1 persisted the attributes every time you set the value of an attribute using bracket notation. **This behavior has been removed.** An explicit `save` operation is now required to persist changes.
{% endhint %}

### Creating and finding instances

There are two ways to create an All Futures class instance: [`new`](../api-reference/class-methods.md#new-attributes) and [`create`](../api-reference/class-methods.md#create-attributes). Both methods accept an optional Hash of attributes:

```ruby
Example.new # no values set, and not yet persisted
Example.new name: "Steve" # not yet persisted
example = Example.new name: "Steve"
example.save # now it's persisted
puts example.id # you'll need the id to access this instance later

Example.create # no values set; persisted but no way to access the id
example_id = Example.create(name: "Bob").id # winning
```

`create` is exactly like `new`, except that the model instance is persisted to Redis before it returns. **If you want to set your own `id` when calling `create`, it's important to specify an `id` value.**

```ruby
Example.create name: "Bob", id: 555
```

Retrieving an instance later just requires passing an `id` to the [`find`](../api-reference/class-methods.md#find-id-find-id1-id2-find-id1-id2) method. Numeric values will be converted to String type for performing the lookup.

```ruby
example = Example.find(example_id)
```

{% hint style="success" %}
In All Futures, [`id`](../api-reference/getter-methods.md#id) is not an attribute. It's not treated as data.
{% endhint %}

### Reserved words

An incomplete list of attribute/method names that you shouldn't use as attributes:

* id
* created\_at
* updated\_at

{% hint style="info" %}
If you are experiencing strange behaviour with an attribute, consider using the `respond_to?` method the see if there is a naming conflict.
{% endhint %}

### Internationalization

I18n in All Futures is similar to [Active Record](https://guides.rubyonrails.org/i18n.html#translations-for-active-record-models).

The root node in your locale YAML is `allfutures` instead of `activerecord`.
