FactoryBot.define do
  factory :partners_user, class: ::User do
    name { "Partner User" }
    sequence(:email) { |n| "partner_user_#{n}@example.com" }
    password { "password!" }
    password_confirmation { "password!" }
    invitation_sent_at { Time.current - 1.day }
    last_sign_in_at { Time.current }
    transient do
      partner { Partner.first || create(:partner) }
    end
    after(:create) do |instance, evaluator|
      instance.add_role(Role::PARTNER, evaluator.partner)
    end
  end
end
