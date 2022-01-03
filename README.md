# All Futures

Rails developers can use the [all\_futures](https://github.com/leastbad/all\_futures) gem to persist data **across multiple requests**. It leverages Redis to provide an ephemeral model that you can use just like an Active Record model.

It's perfect for building faceted search interfaces, multi-step forms, real-time input validation and persisting the display state of UI elements.

Try a demo, here: 👉 [Beast Mode StimulusReflex](https://beastmode.leastbad.com) 👈

[![GitHub stars](https://img.shields.io/github/stars/leastbad/all\_futures?style=social)](https://github.com/leastbad/all\_futures) [![GitHub forks](https://img.shields.io/github/forks/leastbad/all\_futures?style=social)](https://github.com/leastbad/all\_futures) [![Twitter follow](https://img.shields.io/twitter/follow/theleastbad?style=social)](https://twitter.com/theleastbad) [![Discord](https://img.shields.io/discord/629472241427415060)](https://discord.gg/stimulus-reflex)

## Why use All Futures?

Many reactive UI concepts are a pain in the ass to implement using the classic Rails request/response pattern, which was created at a time before developers started using Ajax to update portions of a page. ActionController is amazing, but if a user interaction doesn't fit cleanly into a single form submission, the developer now has to maintain UI state across multiple atomic requests. Naturally, this leads to abuse of the session object and awkward hacks to validate and persist models.

{% hint style="danger" %}
How do you incrementally save models that require the presence of multiple attributes to be valid? In vanilla Rails, _you don't_.
{% endhint %}

The combination of ActionCable and Turbo Drive creates a persistent Connection that blurs the line between session and request, forcing a new mental model that is poorly served by ActionDispatch and the conventions which drove Rails to success... in 2005.

Moving forward, new tooling is required to take full advantage of reactive possibilities.

All Futures presents a flexible and lightweight mechanism to refine a model that persists its attributes across multiple updates, and even multiple servers.

## Is All Futures for you?

Do you ever find yourself:

* building complex search interfaces
* creating multi-stage data entry processes
* frustrated by the limitations of classic form submission
* wanting to save data even if the model is currently invalid
* reinventing the wheel every time you need field validation
* needing granular dirty checking and state management for every attribute

If you answered yes to any of the above... you are every Rails developer, and you're not crazy. This functionality has been a blind-spot in the framework for a long time.

Yes, All Futures is for **you**.

## Key features and advantages

* A natural fit with [StimulusReflex](https://stimulusreflex.com), [Stimulus](https://stimulus.hotwired.dev), [Turbo Drive](https://turbo.hotwired.dev/handbook/drive) and [mrujs](https://mrujs.com)
* No reliance on sessions, so it works across servers
* Easy to learn, quick to implement
* Supports model attributes with defaults, arrays and associations
* Per-attribute dirty checking and state management with rollbacks
* Remembers previous model state across multiple requests
* Automatic versioning allows time travel views
* Model validations, errors and associations
* Can be added as attributes in your Active Record model classes
* No more temporary database tables that need to be purged later

## How does All Futures work?

All Futures is the fusion of [Active Entity](https://github.com/jasl/activeentity) and [Kredis](https://github.com/rails/kredis). It is similar to using a **properly juiced** [ActiveModel::Model](https://api.rubyonrails.org/classes/ActiveModel/Model.html), except that it has full support for [Attributes](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute), including arrays and nested attributes. All Futures classes behave like Active Record model instances as much as possible.

```ruby
class Example < AllFutures::Base
  attribute :name, :string
  validates :name, presence: true
end

example = Example.create
example.valid? # false
example.errors # @errors=[#<ActiveModel::Error attribute=name, type=blank, options={}>]
```

Unlike an Active Record model, All Futures instances can persist their attributes even if the attributes are currently invalid. This design allows you to resolve any errors present, even if it takes several distinct operations to do so.

Once the state of your attributes is valid, you can pass the `attributes` from your All Futures model right into the constructor of a real Active Record model.

{% hint style="danger" %}
All Futures v1 persisted the attributes every time you set the value of an attribute using bracket notation. **This behavior has been removed.** An explicit `save` operation is now required to persist changes.
{% endhint %}

## Who makes this?

First, All Futures wouldn't exist without [Active Entity](https://github.com/jasl/activeentity) and [Kredis](https://github.com/rails/kredis). Thank you, [Jun Jiang](https://twitter.com/jasl9187) and [Kasper Timm Hansen](https://twitter.com/kaspth).

All Futures was originally created by leastbad, who continues to serve as the primary developer and writer of words. :wave:

v2 welcomes pivotal contributions from key members of the [StimulusReflex](https://stimulusreflex.com) core and moderation teams. [Stephen Margheim](https://twitter.com/fractaledmind) heroically made sure that callbacks work as expected, _twice_. [Julian Rubisch](https://twitter.com/julian\_rubisch) is the reason All Futures models are basically interoperable with Active Record models.

Finally, thanks to [Nate Hopkins](https://twitter.com/hopsoft/) and [Konnor Rogers](https://twitter.com/rogerskonnor/) for their feedback and suggestions.

We realized that this library needed to exist and had a deep understanding of how it should work _only_ because we have spent years helping thousands of Rails developers figure out the right way to develop reactive UIs.

All Futures truly was born in fire. :fire:

## Try it now

You can experiment with [Beast Mode StimulusReflex](https://beastmode.leastbad.com), a live demonstration of using All Futures to drill down into a tabular dataset, [**right now**](https://beastmode.leastbad.com). 👈

The Beast Mode [codebase](https://github.com/leastbad/beast\_mode) [![GitHub stars](https://img.shields.io/github/stars/leastbad/beast\_mode?style=social)](https://github.com/leastbad/beast\_mode) [![GitHub forks](https://img.shields.io/github/forks/leastbad/beast\_mode?style=social)](https://github.com/leastbad/beast\_mode) is set up as a **template repo** which I recommend that you clone and experiment with.

The three key files are the [CustomerFilter](https://github.com/leastbad/beast\_mode/blob/master/app/models/customer\_filter.rb), the [Reflex](https://github.com/leastbad/beast\_mode/blob/master/app/reflexes/customers\_reflex.rb) and the [Model](https://github.com/leastbad/beast\_mode/blob/master/app/models/customer.rb). You can read the tutorial post behind this example on my blog [here](https://leastbad.com/beast-mode/).

Assuming you're running at least Ruby 2.7.3, Postgres and have Redis running on your system, you can just run `bin/setup` to install it, including migrations and the DB seed file.

{% embed url="https://www.youtube.com/watch?v=Fbo21aWFbhQ" %}
REFRACT
{% endembed %}
