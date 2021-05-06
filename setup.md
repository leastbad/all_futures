# Setup

Installation is straight-forward: just add the gem to your `Gemfile`:

```ruby
gem "all_futures", "~> 1.0"
```

Since All Futures relies on Redis via the Kredis gem, please make sure that you have a Redis server running and that you have followed the [Kredis installation instructions](https://github.com/rails/kredis#installation).

{% hint style="warning" %}
As of the time of this writing, the Kredis README suggests passing a`host` option in your`redis/shared.yml`- this is not a good idea.

Instead, use the`url` option, which allows you to pass the host, port and password \(if applicable\) in one string.
{% endhint %}



