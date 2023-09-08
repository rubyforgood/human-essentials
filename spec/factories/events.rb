# == Schema Information
#
# Table name: events
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  event_time      :datetime         not null
#  eventable_type  :string
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  eventable_id    :bigint
#  organization_id :bigint
#
FactoryBot.define do
  factory :distribution_event do
    organization
    event_time { Time.zone.now }
  end

  factory :donation_event do
    organization
    event_time { Time.zone.now }
  end
end

