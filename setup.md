# Setup

Installation is straight-forward: just add the gem to your `Gemfile`:

```ruby
gem "all_futures", "~> 2.0"
```

AllFutures relies on Redis via the Kredis gem. Make sure that you have a Redis server running and that you have followed the [Kredis installation instructions](https://github.com/rails/kredis#installation).

If possible, consider running a Redis instance specifically for your AllFutures instances. This will allow maximum flexibility and removes any ambiguity about the purpose of the keys.

{% hint style="warning" %}
As of the time of this writing, the Kredis README suggests passing a`host` option in your`redis/shared.yml`- this is not a good idea.

Instead, use the`url` option, which allows you to pass the host, port and password (if applicable) in one string.
{% endhint %}

## Redis Cache Eviction Policy

AllFutures is designed to create Redis keys on an as-needed basis. No attempt is made to clear keys, as there is an expectation that you will set an [eviction policy](https://docs.redislabs.com/latest/rs/administering/database-operations/eviction-policy/) which will remove old keys to make room for new ones.

The `allkeys-lru` policy is likely your best bet for an AllFutures configuration.
