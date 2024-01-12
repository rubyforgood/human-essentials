# == Schema Information
#
# Table name: partner_requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  for_families    :boolean
#  sent            :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#  partner_id      :bigint
#  partner_user_id :integer
#
FactoryBot.define do
  factory :partner_request do
    bank { nil }
    status { "MyString" }
  end
end
