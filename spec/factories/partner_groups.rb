# == Schema Information
#
# Table name: partner_groups
#
#  id                :bigint           not null, primary key
#  deadline_day      :integer
#  name              :string
#  reminder_schedule :string
#  send_reminders    :boolean          default(FALSE), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  organization_id   :bigint
#

FactoryBot.define do
  recurrence_schedule = IceCube::Schedule.new
  recurrence_schedule.add_recurrence_rule IceCube::Rule.monthly(1).day_of_month(10)
  recurrence_schedule_ical = recurrence_schedule.to_ical

  factory :partner_group do
    sequence(:name) { |n| "Group #{n}" }
    organization { Organization.try(:first) || create(:organization) }
    reminder_schedule { recurrence_schedule_ical }
    deadline_day { 28 }

    trait :without_deadlines do
      reminder_schedule { nil }
      deadline_day { nil }
    end
  end
end
