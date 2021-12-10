# Attributes

### About Virtual Model

Virtual Model is the model not backed by a database table, usually used as "form model" or "presenter", because it's implement interfaces of Active Model, so you can use it like a normal Active Record model in your Rails app.

### Arrays

{% code title="app/models/example.rb" %}
```ruby
class Example < AllFutures::Base
  attribute :tags, :string, array: true, default: []
end
```
{% endcode %}

### Enums

[https://api.rubyonrails.org/v5.2.2/classes/ActiveRecord/Enum.html](https://api.rubyonrails.org/v5.2.2/classes/ActiveRecord/Enum.html)

### Aggregations

[https://api.rubyonrails.org/classes/ActiveRecord/Aggregations/ClassMethods.html](https://api.rubyonrails.org/classes/ActiveRecord/Aggregations/ClassMethods.html)
