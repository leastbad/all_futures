# Usage

Working with All Futures is very similar to working with a Rails model class. You can put your classes into `app/models`, or you might want to create a new folder in your `app` hierarchy to hold multiple classes, depending on your project needs.

## Planning your future

Classes inherit from `AllFutures`:

{% code title="app/filters/customer\_filter.rb" %}
```ruby
class CustomerFilter < AllFutures
  attribute :search, :string
  attribute :state, :string
  attribute :lawyers, :boolean, default: false
  attribute :low, :integer, default: 21
  attribute :high, :integer, default: 65
  attribute :items, :integer, default: 10
  attribute :page, :integer, default: 1
  attribute :order, :string, default: "name"
  attribute :direction, :string, default: "asc"

  def scope
    Customer
      .with_state(state)
      .only_lawyers(lawyers)
      .between(low, high)
      .order(order => direction)
      .search_for(search)
  end
end
```
{% endcode %}

The above code is an example of using All Futures to implement an exclusion filter. It's taken from the [Beast Mode repo](https://github.com/leastbad/beast_mode), and is used to hold the values required to create a faceted search UI for a tabular dataset.

When working with tabular data, there are typically three concerns:

1. Attributes used to exclude and filter data from the total pool of possible values
2. Attributes used to track the current page and number of items per page
3. Attributes used to sort the filtered results in a specific direction \(ASC vs DESC\)

The logic of the above is not intended to describe the data - that's the model's job. Instead, a filter describe the ways a user might want to interrogate it. They start with all possible results and move towards the specific outcome that they're looking for.

For example, the `lawyers` attribute is used to reduce the results to only rows where the name of the employer has the string `and` in it.

{% hint style="success" %}
When designing faceted search UIs, it's important that you handle impossible states so that there are no combinations of filters which could produce invalid combinations or even errors.

For example, it's recommended that you configure Pagy so that a user viewing page 10 is automatically taken to page 5 if the user adjust the number of records per-page from 10 to 20. Set `Pagy::VARS[:overflow] = :last_page` in your `pagy.rb` initializer.
{% endhint %}

While this application didn't require any attribute validation, we did define a `scope` method. It returns an `ActiveRecord::Relation` object which can be used as-is to perform the search, or additional scope clauses can be added to suit the needs of your application.

As you can see in the code above, the actual business logic required to use the attributes stored with All Futures is fully contained in the model as a set of scopes. This `scope` method simply connects the dots to provide access to a relation for _this_ search.

