# Usage

Working with All Futures is very similar to working with a Rails model class. You can put your classes into `app/models`, or you might want to create a new folder in your `app` hierarchy to hold multiple classes, depending on your project needs.

Classes inherit from `Possibility`, because I that's what I decided on:

{% code title="app/filters/customer\_filter.rb" %}
```ruby
class CustomerFilter < Possibility
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

The above code is taken from the [Beast Mode repo](https://github.com/leastbad/beast_mode), and is used to hold the values required to create a faceted search UI for a tabular dataset.

When working with tabular data, there are typically three concerns: 

1. Attributes used to exclude and filter data from the total pool of possible values
2. Attributes used to track the current page and number of items per page
3. Attributes used to sort the filtered results in a specific direction \(ASC vs DESC\)

The logic of the above is not intended to describe the data so much as describe the infinite ways users might want to slice and dice it, moving from all possible results to the specific outcome that they're looking for.

For example, the `lawyers` attribute is used to reduce the results to only rows where the name of the employer has the string `and` in it.

While this application didn't require any attribute validation, we did define a `scope` method. It returns an `ActiveRecord::Relation` object which can be used as-is to perform the search, or additional scope clauses can be added to suit the needs of your application.

