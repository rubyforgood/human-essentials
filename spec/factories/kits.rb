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
    sequence(:name) { |n| "Default Kit Name #{n} - Don't Match" }
    organization

    after(:build) do |instance, _|
      if instance.line_items.blank?
        instance.line_items << build(:line_item, item: create(:item, organization: instance.organization), itemizable: nil)
      end
    end

    # See #3652, changes to this factory are in progress
    # For now, to create corresponding item and line item and persist to database call create_kit
    # from spec/support/kit_helper.rb
  end
end
