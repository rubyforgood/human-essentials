FactoryBot.define do
  factory :partners_user, class: Partners::User do
    name { "Partner User" }
    email { "partner_user@example.com" }
    partner { Partners::Partner.first || create(:partners_partner) }
    password { "password!" }
    password_confirmation { "password!" }
  end
end
