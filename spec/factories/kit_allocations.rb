# == Schema Information
#
# Table name: kit_allocations
#
#  id                  :bigint           not null, primary key
#  kit_allocation_type :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  kit_id              :bigint           not null
#  organization_id     :bigint           not null
#  storage_location_id :bigint           not null
#
FactoryBot.define do
  factory :kit_allocation do
  end
end
