FactoryBot.define do
  factory :partners_family, class: Partners::Family do
    association :partner

    comments                  { Faker::Lorem.paragraph }
    # Faker doesn't have county, community is same flavour, we don't use it, and it is not country.
    guardian_county           { Faker::Address.community }
    guardian_employed         { false }
    guardian_employment_type  { nil }
    guardian_first_name       { Faker::Name.first_name }
    guardian_health_insurance { nil }
    guardian_last_name        { Faker::Name.last_name }
    guardian_monthly_pay      { rand(500.0..2000.0).round(2) }
    guardian_phone            { Faker::PhoneNumber.phone_number_with_country_code }
    guardian_zip_code         { Faker::Address.zip }
    home_adult_count          { rand(1..5) }
    home_child_count          { rand(0..5) }
    home_young_child_count    { rand(0..5) }
    military                  { false }
    archived                  { false }
  end
end
