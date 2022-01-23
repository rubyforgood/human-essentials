# == Schema Information
#
# Table name: partner_groups
#
#  id                    :bigint           not null, primary key
#  deadline_day_of_month :integer
#  name                  :string
#  reminder_day_of_month :integer
#  send_reminders        :boolean          default(FALSE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  organization_id       :bigint
#

FactoryBot.define do
  factory :partner_group do
    sequence(:name) { |n| "Group #{n}" }
    organization { Organization.try(:first) || create(:organization) }
    reminder_day_of_month { 14 }
    deadline_day_of_month { 28 }

    trait :without_deadlines do
      reminder_day_of_month { nil }
      deadline_day_of_month { nil }
    end
  end
end
