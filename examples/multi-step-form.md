# Multi-step form

The classic pain: a wizard that needs three screens of data before the Active Record model is valid. All Futures is happy to stay invalid until you're ready.

```ruby
class Onboarding < AllFutures::Base
  attribute :email, :string
  attribute :company, :string
  attribute :plan, :string
  attribute :step, :integer, default: 1

  validates :email, presence: true, if: -> { step >= 1 }
  validates :company, presence: true, if: -> { step >= 2 }
  validates :plan, presence: true, if: -> { step >= 3 }
end
```

```ruby
# step 1
onboarding = Onboarding.create(email: params[:email], step: 1)
onboarding.save # persists even if later steps are blank

# step 2 (later request)
onboarding = Onboarding.find(session[:onboarding_id])
onboarding.update(company: params[:company], step: 2)

# step 3 — promote to a real record when valid
onboarding = Onboarding.find(session[:onboarding_id])
onboarding.assign_attributes(plan: params[:plan], step: 3)
if onboarding.valid?
  User.create!(onboarding.attributes.slice("email", "company", "plan"))
  onboarding.destroy
else
  onboarding.save # keep the draft + errors for the UI
end
```

Stamp `onboarding.id` into the form (or session) the same way Beast Mode stamps `filter.id` — that id is your continuity across requests.
