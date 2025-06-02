# == Schema Information
#
# Table name: partner_groups
#
#  id                           :bigint           not null, primary key
#  deadline_day                 :integer
#  name                         :string
#  reminder_day                 :integer
#  reminder_schedule_definition :string
#  send_reminders               :boolean          default(FALSE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  organization_id              :bigint
#

FactoryBot.define do
  reminder_schedule_definition = ReminderScheduleService.new({
    every_nth_month: "1",
    by_month_or_week: "day_of_month",
    day_of_month: 10
  })

  factory :partner_group do
    sequence(:name) { |n| "Group #{n}" }
    organization { Organization.try(:first) || create(:organization) }
    reminder_schedule_definition { reminder_schedule_definition.to_ical }

    trait :without_deadlines do
      reminder_schedule_definition { nil }
      deadline_day { nil }
    end
  end
end
