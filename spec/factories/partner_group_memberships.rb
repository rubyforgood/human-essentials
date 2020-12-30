# == Schema Information
#
# Table name: partner_group_memberships
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  partner_group_id :bigint
#  partner_id       :bigint
#

FactoryBot.define do
  factory :partner_group_membership do
    partner_group
    partner
  end
end
