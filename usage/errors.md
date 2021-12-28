# Errors

AllFutures supports the same `errors` mechanism (technically, an instance of `ActiveModel::Errors`) as Active Record. When validations fail, instances of `ActiveModel::Error` will be added to the `errors.objects` Array.

{% hint style="info" %}
`errors.objects` is actually just an alias for `errors.errors`, which is just not pretty enough for Rails. :see\_no\_evil:
{% endhint %}

When a model is initialized, its `errors` collection is empty, but when you run `save` or `update`, it runs `valid?` behind the scenes. (You can also run `valid?` without attempting to save.) If `valid?` returns `false`, it's the `errors` collection that allows you to assess what went wrong and proceed accordingly.

Many Rails developers think of `errors` as "the thing generated resources use to show validation failure messages" and don't take the time to learn the API inside and out. AllFutures gives developers a compelling reason to learn what `errors` has to offer someone building a reactive UI.

{% hint style="warning" %}
In the interest of readability, I am omitting the `errors` accessor from every method call in this chapter. When you read `full_messages_for(:name)` it is a stand-in for:

```ruby
record.errors.full_messages_for :name
```
{% endhint %}

### `full_messages` vs `messages`

Error messages are available with (`full_messages`) and without (`messages`) the attribute name prefixed, meaning that you're talking about the choice between "Name is invalid" and "is invalid".

Both are useful in different situations; you might not want an awkwardly-named attribute being converted into a proper noun, such as "State Province can't be empty".

The key to enlightenment is to spend time studying (and potentially modifying) [the locale file](https://github.com/rails/rails/blob/main/activemodel/lib/active\_model/locale/en.yml)s for the languages that you support. Of course, you can also [specify messages](https://guides.rubyonrails.org/active\_record\_validations.html#message) on a per-validation basis, but that makes internationalization difficult.

### Working with `errors`

errors.any?

errors.size

errors.full\_messages

errors.messages

errors.attribute\_names

errors.include? / key? / has\_key?

errors\[:attribute]

errors.objects

errors.messages\_for(:attribute) / errors.full\_messages\_for(:attribute)

errors.where(:name, :too\_short, minimum: 2)

errors.added? :name, "can't be blank"

errors.of\_kind?

errors.add

errors.delete(:name)

errors.clear

