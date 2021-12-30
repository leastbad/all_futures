# Errors

AllFutures supports the same error handling pipeline as Active Record, `errors`, which is an enumerable instance of `ActiveModel::Errors`.

When validations fail, `ActiveModel::Error` instances will be added to the `errors.objects` Array. `objects` is actually just an alias for `errors.errors`, which is _just not pretty enough_ for Rails. :see\_no\_evil:

{% hint style="success" %}
In the interest of brevity and readability, the receiver and `errors` object have been omitted from every reference to a method in this chapter.

When you read `full_messages_for :name`, it is a stand-in for `record.errors.full_messages_for :name`.
{% endhint %}

When a model is initialized, its `objects` Array is empty until you either call `save` / `update` or invoke `valid?` directly. `valid?` returns `false` if at least one validation failed.

{% hint style="danger" %}
The `valid?` method clears the `objects` Array, which means that **adding errors will not make a model invalid**. Instead, it's failed validations that typically add the errors.
{% endhint %}

Our goal is to respond to this invalid state as part of the normal user experience, without actually raising an application level exception. To achieve this "successful failure", Rails gives us a family of methods that operate on the `objects` Array.&#x20;

Many Rails developers think of `errors` as "the thing generated resources use to show validation failure messages". AllFutures offers developers several compelling reasons to learn what `ActiveModel::Errors` has to offer someone building a reactive UI.

### `full_messages` vs `messages`

Error messages are available with (`full_messages`) and without (`messages`) the attribute name prefixed, offering you a choice between "Name is invalid" and "is invalid".

Both are useful in different situations; you might not want an awkwardly-named attribute being converted into a proper noun, such as "State Province can't be empty".

The key to enlightenment is to spend time studying (and potentially modifying) [the locale file](https://github.com/rails/rails/blob/main/activemodel/lib/active\_model/locale/en.yml)s for the languages that you support. Of course, you can also [specify messages](https://guides.rubyonrails.org/active\_record\_validations.html#message) on a per-validation basis, but that can add complexity to your internationalization strategy.

### Working with `ActiveModel::Errors`

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

