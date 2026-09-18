# Setup

Installation is straight-forward: just add the gem to your `Gemfile`:

```ruby
gem "all_futures", "~> 2.0"
```

**Ruby 3.1+** and **Rails 7.1+** (including 8.x) are required. The suite is green on Rails 8.1.

All Futures relies on Redis via the `kredis` gem (`~> 1.8`). Make sure you have a Redis server running and that you have followed the [Kredis installation instructions](https://github.com/rails/kredis#installation) to set up your `config/redis/shared.yml`.

Rails 7 and 8 ship with Kredis-friendly defaults; you still need Redis itself.

### Optional: atomic optimistic locking

Versioned models get a best-effort stale check by default. For a Redis Lua compare-and-set on every versioned write:

```ruby
# config/application.rb
config.all_futures.atomic_locking = true
```

See [Versioning](usage/versioning.md) for the full story. Leave it `false` unless you know you need it.

## Redis Cache Eviction Policy

All Futures is designed to create Redis keys on an as-needed basis. No attempt is made to clear keys, as there is an expectation that you will set an [eviction policy](https://docs.redislabs.com/latest/rs/administering/database-operations/eviction-policy/) which will remove old keys to make room for new ones.

The `allkeys-lru` or `volatile-lru` policy is likely your best bet for an All Futures configuration, depending on whether you use the `expire` option.

## Configuring Redis

If possible, consider two Redis instances for your application; one with a `noeviction` policy for Sidekiq and other queues that you want to complain loudly if they are filling up, and one `allkeys-lru` for Rails caching and All Futures.

This will allow maximum flexibility and takes advantage of the automatic cache expiration to ensure that your Redis instance will always remain available with a minimum of oversight required, even under load.

### Hiredis

[`hiredis-rb`](https://github.com/redis/hiredis-rb) is billed as a wrapper around the high-performance native Redis library. For a long time, it seemed like a no-brainer to use it because who doesn't love "fast"?

However, SSL support historically lagged, which is problematic in many deployment environments. Redis is usually the fastest part of a request anyhow — take hiredis if you need it, skip it if you don't.
