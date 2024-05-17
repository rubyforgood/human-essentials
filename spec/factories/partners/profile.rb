FactoryBot.define do
  factory :partner_profile, class: Partners::Profile do
    partner { Partner.first || create(:partner) }
    essentials_bank_id { Organization.try(:first).id || create(:organization).id }
    website { "http://some-site.org" }
    primary_contact_email { Faker::Internet.email }
    primary_contact_name { Faker::Name.name }
  end
end
