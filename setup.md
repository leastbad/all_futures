# Setup

Installation is straight-forward: just add the gem to your `Gemfile`:

```ruby
gem "all_futures", "~> 2.0"
```

All Futures relies on Redis via the `kredis` gem. Make sure that you have a Redis server running and that you have followed the [Kredis installation instructions](https://github.com/rails/kredis#installation) to set up your `config/redis/shared.yml`.

Thankfully, Rails 7 now ships with Kredis installed, which means you should be able to use All Futures going forward. Note that **Kredis requires Ruby 2.7 or above**.

## Redis Cache Eviction Policy

All Futures is designed to create Redis keys on an as-needed basis. No attempt is made to clear keys, as there is an expectation that you will set an [eviction policy](https://docs.redislabs.com/latest/rs/administering/database-operations/eviction-policy/) which will remove old keys to make room for new ones.

The `allkeys-lru` or `volatile-lru` policy is likely your best bet for an All Futures configuration, depending on whether you use the `expire` option.

## Configuring Redis

If possible, consider two Redis instances for your application; one with a `noeviction` policy for Sidekiq and other queues that you want to complain loudly if they are filling up, and one `` allkeys-lru` `` for Rails caching and All Futures.

This will allow maximum flexibility and takes advantage of the automatic cache expiration to ensure that your Redis instance will always remain available with a minimum of oversight required, even under load.

### Hiredis

``[`hiredis-rb`](https://github.com/redis/hiredis-rb) is billed as a wrapper around the high-performance native Redis library. For a long time, it seemed like a no-brainer to use it because who doesn't love "fast"?

However, for reasons that are not entirely clear, at the time of this writing, the `hiredis` gem still doesn't appear to support SSL connections. This is problematic in many deployment environments, and the delay has caused many Rails developers to question whether they _really_ need the added complexity, given Redis is usually the fastest part of a request anyhow.
