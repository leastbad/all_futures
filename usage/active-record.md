# Active Record

All Futures is designed to compliment Active Record and make it easier to use in a reactive context. To this end, it implements many of the same interfaces and features - allowing you to use an All Futures model just about anywhere that you can use an Active Record model.

### Association-style accessors: `has_future`

You can mount an All Futures record as an accessor in an Active Record model using the `has_future` class method, which is conceptually similar to the `has_one` association. It requires that you provide an accessor name and an All Futures model class as parameters.

```ruby
class Post < ApplicationRecord
  has_future :draft, PostDraft
end

post = Post.find(params[:id])
post.draft.title = "nihil admirari"
post.draft.save
```

{% hint style="danger" %}
All Futures models provided by `has_future` can only be accessed **after** the parent Active Record model has been persisted. If you attempt to access the model before the parent is persisted, an `AllFutures::ParentModelNotSavedYet` exception will be raised.
{% endhint %}

You can provide your own custom key:

```ruby
class Post < ApplicationRecord
  has_future :draft, PostDraft, key: ->(p) { "posts:#{p.id}:draft" }
end 
```

Attached All Futures models have not been persisted to Redis when they are first accessed. **You must call `save` on them if you want attribute data to persist.** Of course, you might not! Such is the flexibility you have at your disposal.

### Creating or updating from an Active Record model

Assuming that you have compatible attributes, you can pass an Active Record model as a parameter to an All Futures model's `create` or `update` method:

```ruby
draft = PostDraft.new Post.last
```

Behind the scenes, `PostDraft` strips out the `:id`, `:created_at` and `:updated_at` attributes, if they exist.

{% hint style="danger" %}
If your Active Record model has attributes that your All Futures model does not, passing it to `create` or `update` will raise an `ActiveModel::UnknownAttributeError`.
{% endhint %}

### Creating or updating from an All Futures model

Assuming that you have compatible attributes, you can pass an All Futures model as a parameter to an Active Record model's `create` or `update` method:

```ruby
class PostDraft < AllFutures::Base
  attribute :title, :string
  attribute :body, :string
end

draft = PostDraft.new title: "hello", body: "tbd"

post = Post.create draft
```

Behind the scenes, `Post` is actually calling `reject` on our `PostDraft` model; All Futures implements a `reject` method that returns `attributes`. In the example above, you could also pass the full `draft.attributes` to `Post.create` if you hate brevity.

If you are using the All Futures versioning mechanism, you can pass a version to `create` or `update` in the same manner:

```ruby
class PostDraft < AllFutures::Base
  attribute :title, :string
  attribute :body, :string
  enable_versioning!
end

draft = PostDraft.create title: "hello", body: "tbd"
draft.update! body: "still thinking"

post = Post.create draft.version(2)
```

{% hint style="danger" %}
If your All Futures model has attributes that your Active Record model does not, passing it to `create` or `update` will raise an `ActiveModel::UnknownAttributeError`.
{% endhint %}

### Cache Keys

All Futures models maintain an internal `@updated_at` accessor so that they can be used as cache keys and invalidate themselves when appropriate.

### Excluding attributes

You might encounter scenarios where you have models that are close to identical but might have additional attributes. This will cause issues if you attempt to pass the `attributes` of the superset model into the constructor of the subset.

This can be remedied by excluding the attributes you don't want to pass:

```ruby
Post.create PostDraft.find(3).attributes.except("attribute1", "attribute2")
```

If you find that you're accessing this subset of attributes often, you could create a method on your model to DRY up your code:

```ruby
def without_attrs
  attributes.except("attribute1", "attribute2")
end
```

{% hint style="info" %}
Remember to use String-based keys when accessing items in your `attributes` collection.
{% endhint %}
