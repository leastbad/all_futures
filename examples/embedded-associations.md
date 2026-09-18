# Embedded associations

{% hint style="warning" %}
Experimental — API may still move.
{% endhint %}

```ruby
class Cart < AllFutures::Base
  embeds_many :items, dependent: :destroy, autosave: true
end

class Item < AllFutures::Base
  attribute :cart_id
  attribute :sku, :string
  attribute :qty, :integer, default: 1
  embedded_in :cart
end

cart = Cart.new
cart.items.build(sku: "duck-001", qty: 2)
cart.items.build(sku: "duck-002")
cart.save

# later request — children lazy-load on first touch
cart = Cart.find(cart.id)
cart.items.map(&:sku) # => ["duck-001", "duck-002"]
```

Children can also be created on their own if you set the foreign key; they still appear when the parent is loaded:

```ruby
Item.create(cart_id: cart.id, sku: "duck-003")
Cart.find(cart.id).items.size # => 3
```
