FactoryBot.define do
  factory :partners_user, class: Partners::User do
    email { Faker::Internet.email }
    password { 'password' }

    after(:build) do |partner_user, _option|
      partner = FactoryBot.create(:partners_partner, name: partner_user.email)
      partner_user.partner_id = partner.id
    end
  end
end


