FactoryBot.define do
  factory :partner_profile, class: Partners::Profile do
    partner { Partner.first || create(:partner) }
    essentials_bank_id { Organization.try(:first).id || create(:organization).id }
    website { "http://some-site.org" }
    name { Faker::Company.name }
    agency_type { Partner::AGENCY_TYPES['CAREER'] }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip_code { Faker::Address.zip}
    address1 { Faker::Address.street_address }
    program_name { Faker::Lorem.characters(number:5) }
    program_description { Faker::Lorem.characters(number:15) }
  end
end
