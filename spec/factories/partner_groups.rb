# == Schema Information
#
# Table name: partner_groups
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

FactoryBot.define do
  factory :partner_group do
    sequence(:name) { |n| "Group #{n}" }
    organization { Organization.try(:first) || create(:organization) }
  end
end
