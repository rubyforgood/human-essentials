# == Schema Information
#
# Table name: partners
#
#  id                          :integer          not null, primary key
#  email                       :string
#  name                        :string
#  notes                       :text
#  quota                       :integer
#  send_reminders              :boolean          default(FALSE), not null
#  status                      :integer          default("uninvited")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  default_storage_location_id :bigint
#  organization_id             :integer
#  partner_group_id            :bigint
#

FactoryBot.define do
  factory :partner do
    sequence(:name) { |n| "Leslie Sue, the #{n}" }
    sequence(:email) { |n| "leslie#{n}@gmail.com" }
    notes { "Lorem ipsum" }
    send_reminders { true }
    organization_id { Organization.try(:first).try(:id) || create(:organization).id }

    trait :approved do
      status { :approved }
    end

    trait :uninvited do
      status { :uninvited }

      transient do
        without_profile { false }
      end
    end

    trait :awaiting_review do
      status { :awaiting_review }
    end

    after(:create) do |partner, evaluator|
      next if evaluator.try(:without_profile)

      # Create associated records
      create(:partner_profile, partner_id: partner.id)
      create(:partners_user, email: partner.email, name: partner.name, partner: partner)
    end
  end
end
