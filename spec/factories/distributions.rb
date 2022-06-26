# == Schema Information
#
# Table name: distributions
#
#  id                     :integer          not null, primary key
#  agency_rep             :string
#  comment                :text
#  delivery_method        :integer          default("pick_up"), not null
#  issued_at              :datetime
#  reminder_email_enabled :boolean          default(FALSE), not null
#  state                  :integer          default("scheduled"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  organization_id        :integer
#  partner_id             :integer
#  storage_location_id    :integer
#

FactoryBot.define do
  factory :distribution do
    storage_location
    partner
    organization { Organization.try(:first) || create(:organization) }
    issued_at { nil }
    delivery_method { :pick_up }
    state { :scheduled }

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      storage_location { create :storage_location, :with_items, item: item, organization: organization }

      after(:build) do |instance, evaluator|
        item = if evaluator.item.nil?
                 instance.storage_location.inventory_items.first.item
               else
                 evaluator.item
               end
        instance.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
