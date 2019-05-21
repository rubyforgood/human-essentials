FactoryBot.define do
  factory :manufacturer do
    organization { Organization.try(:first) || create(:organization) }
    sequence(:name) { |n| "Manufacturer #{n}" }
  end
end
