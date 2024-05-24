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
#  shipping_cost          :decimal(8, 2)
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

    trait :past do
      issued_at { 1.week.ago }
      created_at { 10.days.ago }
    end

    trait :with_items do
      transient do
        item_quantity { 100 }
        item { nil }
      end

      storage_location { create :storage_location, :with_items, item: item, organization: organization }

      after(:build) do |instance, evaluator|
        # Don't remove this. Shortcutting does not work
        event_item = View::Inventory.new(instance.organization_id)
          .items_for_location(instance.storage_location_id)
          .first
          &.db_item
        item = evaluator.item || event_item
        instance.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: instance)
      end
    end
  end
end
