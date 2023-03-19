# == Schema Information
#
# Table name: broadcast_announcements
#
#  id              :bigint           not null, primary key
#  expiry          :date
#  link            :text
#  message         :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#  user_id         :bigint           not null
#
FactoryBot.define do
  factory :broadcast_announcement do
    user
    organization
    message { "test" }
  end
end
