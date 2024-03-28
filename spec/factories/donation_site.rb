FactoryBot.define do
  factory :donation_site do
    organization { Organization.try(:first) || create(:organization) }
    name { Faker::Company.name }
    address { "1500 Remount Road, Front Royal, VA 22630" }
    active { true }
    contact_name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
  end
end
