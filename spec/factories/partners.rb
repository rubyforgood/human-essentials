# == Schema Information
#
# Table name: partners
#
#  id               :integer          not null, primary key
#  email            :string
#  name             :string
#  notes            :text
#  quota            :integer
#  send_reminders   :boolean          default(FALSE), not null
#  status           :integer          default("uninvited")
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organization_id  :integer
#  partner_group_id :bigint
#

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Leslie Sue, the #{n}" }
    sequence(:email) { |n| "leslie#{n}@gmail.com" }
    send_reminders { true }
    organization_id { Organization.try(:first).try(:id) || create(:organization).id }

    trait :approved do
      status { :approved }
    end

    trait :uninvited do
      status { :uninvited }
    end

    trait :awaiting_review do
      status { :awaiting_review }
    end

    after(:create) do |partner, _evaluator|
      # Create associated records on partnerbase DB
      partners_partner = create(:partners_partner, diaper_bank_id: partner.organization_id, diaper_partner_id: partner.id, name: partner.name)
      Partners::User.create!(
        email: partner.email,
        partner: partners_partner,
        password: 'password!'
      )
    end
  end
end
