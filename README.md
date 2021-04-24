# All Futures

The [all\_futures](https://github.com/leastbad/all_futures) gem offers Rails developers a way to **gather attributes** on an unsaved model **across multiple requests**. It's perfect for [StimulusReflex](https://docs.stimulusreflex.com/) users that are building faceted search interfaces, as well as [Optimism](https://optimism.leastbad.com/) users looking to implement real-time, per-attribute validation schemes.

Try a demo, here: 👉 [Beast Mode StimulusReflex](https://beastmode.leastbad.com/) 👈

[![GitHub stars](https://img.shields.io/github/stars/leastbad/all_futures?style=social)](https://github.com/leastbad/all_futures) [![GitHub forks](https://img.shields.io/github/forks/leastbad/all_futures?style=social)](https://github.com/leastbad/all_futures) [![Twitter follow](https://img.shields.io/twitter/follow/theleastbad?style=social)](https://twitter.com/theleastbad) [![Discord](https://img.shields.io/discord/681373845323513862)](https://discord.gg/GnweR3)

## Why use All Futures?

Many reactive UI concepts are a pain in the ass to implement using the classic Rails request/response pattern, which was created at a time before developers started using Ajax to update portions of a page. ActionController is designed to mutate state in response to form submissions, leading to abuse of the session object and awkward hacks to validate and persist models across multiple requests.

All Futures presents a flexible and lightweight mechanism to refine a model that persists its attributes across multiple updates, and even multiple servers.

## Is All Futures for you?

Do you ever find yourself:

* building complex search interfaces
* creating multi-stage data entry processes
* frustrated by the limitations of classic form submission
* wanting to save data even if the model is currently invalid
* reinventing the wheel every time you need field validation

If you answered yes to any of the above... you are every Rails developer, and you're not crazy. This functionality has been a blind-spot in the framework for a long time.

Yes, All Futures is for **you**.

## Key features and advantages

* A natural fit with [StimulusReflex](https://docs.stimulusreflex.com/) and [Stimulus](https://stimulus.hotwire.dev/)
* No reliance on sessions, so it works across servers
* Easy to learn, quick to implement
* Supports model attributes, validations and errors
* No need to mess around with temporary records

## How does All Futures work?

First, set up an All Futures class that defines some attributes:

```ruby
class ExampleModel < Possibility
  attribute :name, :string
  attribute :age, :integer, default: 21
end
```

Then create an instance and assign it to an instance variable in the controller responsible for your initial page load:

```ruby
class ExampleController < ApplicationController
  def index
    @af = ExampleModel.new
  end
end
```

Emit the instance id as a data attribute on every element which can update your model:

```text
Name: <input type="text" data-af="<%= @af.id %>" data-reflex="input->Example#name" /><br/>
Age: <input type="text" data-af="<%= @af.id %>" data-reflex="input->Example#age" placeholder="<%= @id.age %>" />
```

Since all attributes are gathered and sent to the server during a Reflex operation, it's easy to retrieve the instance id from the Reflex element accessor and use it to call up the correct All Futures object and make changes to it:

```ruby
class ExampleReflex < ApplicationReflex
  def name
    model = ExampleModel.find(element.dataset.af)
    model[:name] = element.value
  end
  
  def age
    model = ExampleModel.find(element.dataset.af)
    model[:age] = element.value
  end
end
```

The current state of the attributes is persisted every time you set the value of an attribute using bracket notation. You can use standard setter assignments, but the model state will not be persisted until you manually call `save`:

```ruby
model[:name] = "Helen" # saved
model.name = "Helen" # not saved
model.save # saved
```

{% hint style="warning" %}
All Futures class attributes are persisted in Redis via the excellent [Kredis](https://github.com/rails/kredis) gem, which must be set up and running in your project before you can use All Futures.
{% endhint %}

All Futures is based on [Active Entity](https://github.com/jasl/activeentity). It is similar to using [ActiveModel::Model](https://api.rubyonrails.org/classes/ActiveModel/Model.html), except that it has full support for [Attributes](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute), including arrays and nested attributes. All Futures classes behave like ActiveModel classes, so you can inspect `valid?` and the `errors` accessor.

```ruby
class ExampleModel < Possibility
  attribute :name, :string
  validates :name, presence: true
end

model = ExampleModel.new
model.valid? # false
model.errors # @errors=[#<ActiveModel::Error attribute=name, type=blank, options={}>]
```

{% hint style="info" %}
Unlike an ActiveRecord model, All Futures instances can persist their attributes even if the attributes are currently invalid. This design allows you to resolve any errors present, even if it takes several distinct operations to do so.
{% endhint %}

{% hint style="success" %}
Once the state of your attributes is valid, you can pass the `attributes` from your All Futures model right into the constructor of a real ActiveRecord model. It should work perfectly.
{% endhint %}

## Try it now

You can experiment with [Beast Mode StimulusReflex](https://beastmode.leastbad.com/), a live demonstration of using All Futures to drill down into a tabular dataset, [**right now**](https://beastmode.leastbad.com/). 👈

The Beast Mode [codebase](https://github.com/leastbad/beast_mode) [![GitHub stars](https://img.shields.io/github/stars/leastbad/all_futures?style=social)](https://github.com/leastbad/all_futures) [![GitHub forks](https://img.shields.io/github/forks/leastbad/beast_mode?style=social)](https://github.com/leastbad/beast_mode) is set up as a template repo which I recommend that you clone and experiment with.

Assuming you're running Ruby 2.7.3, Postgres and have Redis running on your system, you can just run `bin/setup` to install it, including migrations and the DB seed file.

{% embed url="https://www.youtube.com/watch?v=Fbo21aWFbhQ" caption="Did they meet at the gym?" %}

