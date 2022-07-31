FactoryBot.define do
  factory :partner_user, class: ::User do
    name { "Partner User" }
    sequence(:email) { |n| "partner___user_#{n}@example.com" }
    partner { Partners::Partner.first || create(:partners_partner) }
    password { "password!" }
    password_confirmation { "password!" }
    invitation_sent_at { Time.current - 1.day }
    last_sign_in_at { Time.current }
  end
end
