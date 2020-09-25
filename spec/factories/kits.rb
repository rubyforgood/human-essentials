# == Schema Information
#
# Table name: kits
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE)
#  name                :string
#  value_in_cents      :integer          default(0)
#  visible_to_partners :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer
#
FactoryBot.define do
  factory :kit do
    name { "Test Kit" }
    organization

    after(:build) do |instance, _|
      instance.line_items << create(:line_item)
    end
  end
end
