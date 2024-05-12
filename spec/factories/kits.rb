# == Schema Information
#
# Table name: kits
#
#  id                  :bigint           not null, primary key
#  active              :boolean          default(TRUE)
#  name                :string           not null
#  value_in_cents      :integer          default(0)
#  visible_to_partners :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  organization_id     :integer          not null
#
FactoryBot.define do
  factory :kit do
    sequence(:name) { |n| "Test Kit #{n}" }
    organization

    after(:build) do |instance, _|
      if instance.line_items.blank?
        instance.line_items << create(:line_item, item: create(:item, organization: instance.organization), itemizable: instance)
      end
    end

    trait :with_item do
      after(:create) do |instance, _|
        create(:item, kit: instance, organization: instance.organization)
      end
    end
  end
end
