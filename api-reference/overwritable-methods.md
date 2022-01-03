# Overwritable Methods

### Methods to overwrite

These methods are already defined on your All Futures class. 90% of the time, these defaults are great. If you have complex needs, you can redefine them with your own logic.

#### to\_dom\_id

Responsible for converting the model instance into a valid DOM `id`. Can be passed to a StimulusReflex Morph and used as a CableReady `selector`. Converts namespaced classes to double-dashes.

```ruby
def to_dom_id
  [self.class.name.underscore.dasherize.gsub("/", "--"), id].join("-")
end
```

{% hint style="warning" %}
Only [ASCII](https://developer.mozilla.org/en-US/docs/Glossary/ASCII) letters, digits, `_`, and `-` should be used for an `id`. The `id` attribute should start with a letter.

**Do** **not** add a `#` prefix to the return value.
{% endhint %}

#### to\_key

If you attempt to sort two objects of the same class, Ruby will call the `to_key` method and use the Array it returns to sort. By default, the `to_key` Array contains the `id`. Since All Futures models frequently have a UUIDv4 `id`, this isn't a useful sorting criteria.

You can specify one or more attributes - or other values - to sort by instead.

```ruby
def to_key
  [name, age, id]
end
```

#### to\_param

Returns a String representing the model's key suitable for use in URLs, or `nil` if `persisted?` is `false`. The key is usually the `id`, but this can be overwritten to provide vanity URL slugs.

```ruby
def to_param
  "#{id}-#{title}"
end
```

#### to\_partial\_path

Active Record model instances can be passed to Rails' `render` method, and if ActionPack can locate a partial in the correct location based on that model, it will render that partial. `to_partial_path` is responsible for this magic.

All Futures models can also be passed to `render`. If you have a `Drafts` model, `to_partial_path` returns `drafts/draft` and ActionPack will look for `app/views/drafts/_draft.html.erb`. If this isn't where the partial for your model is located, define your own:

```ruby
def to_partial_path
  "article_drafts/preview"
end
```

ActionPack will now attempt to render `app/views/article_drafts/_preview.html.erb`.

#### readonly?

Query `readonly?` to see if this model instance has been marked as `readonly`, which prevents all `save`, `update` and `destroy` operations.

Want to ensure that no changes are written to Redis for this model class, ever?

```ruby
def readonly?
  true
end
```
