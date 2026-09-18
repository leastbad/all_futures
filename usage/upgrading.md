# Updating from v1

Welcome back. If you were on the old auto-persist-everything train, this page is your layover. v2 is the same duck, just house-trained: **you have to call `save`**.

## Requirements

| | v1 era | v2 |
|---|---|---|
| Ruby | 2.7+ | **3.1+** |
| Rails | 6.x-ish | **7.1+** (tested through 8.1) |
| Persist on assign | yes (bracket writes) | **no — explicit `save`** |
| Version number | 1.0.x | **2.0.0** |

## Gemfile

```ruby
# before
gem "all_futures", github: "leastbad/all_futures", branch: "master"

# after
gem "all_futures", "~> 2.0"
```

Then `bundle update all_futures`.

## The big break: explicit saves

v1 wrote to Redis whenever you did `model[:name] = "x"` (and friends). That was clever and also a footgun.

```ruby
# v1
filter = CustomerFilter.find(id)
filter.search = "ste"   # already in Redis 😬

# v2
filter = CustomerFilter.find(id)
filter.search = "ste"   # memory only
filter.save             # now it's in Redis
```

Audit every Reflex, controller, and job that mutates an All Futures model. If it assigns attributes and expects persistence, add `save` / `save!` / `update` / `update!`.

Beast Mode's Reflex pattern already did the right thing:

```ruby
filter = CustomerFilter.find(element.dataset.filter)
yield filter
filter.save
```

If your app looked like that, you are already most of the way home.

## Versioning and stale writes

Versioning is still opt-in per class (`enable_versioning!`). Concurrent updates to a versioned model raise `AllFutures::RecordStale` instead of silently clobbering.

If you need a real compare-and-set (not just a best-effort guard rail):

```ruby
# config/application.rb
config.all_futures.atomic_locking = true
```

Default is `false`. See [Versioning](versioning.md).

## Associations

`embeds_one` / `embeds_many` / `embedded_in` now persist children as their own Redis records and **lazy-load** them when you touch the association after `find`. This layer is still marked experimental — read [Associations](associations.md) before you bet the farm on it.

## Kredis

All Futures expects Kredis `~> 1.8` and a working `config/redis/shared.yml`. Rails 7+ apps usually already have this; Rails 8 apps definitely should.

## Smoke test your upgrade

1. Create a record, `find` it in another request, mutate, `save`, `find` again — values must stick.
2. Assign without `save` — Redis must **not** change.
3. If you use versioning, open two copies, save one, save the other — expect `RecordStale`.

When those three pass, you are on v2 in spirit as well as in `Gemfile.lock`.
