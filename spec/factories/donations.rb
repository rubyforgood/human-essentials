# == Schema Information
#
# Table name: donations
#
#  id                           :integer          not null, primary key
#  comment                      :text
#  issued_at                    :datetime
#  money_raised                 :integer
#  source                       :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  donation_site_id             :integer
#  manufacturer_id              :bigint
#  organization_id              :integer
#  product_drive_id             :bigint
#  product_drive_participant_id :integer
#  storage_location_id          :integer
#

FactoryBot.define do
  factory :donation do
    source { Donation::SOURCES[:misc] }
    comment { "It's a fine day for diapers." }
    storage_location
    organization { Organization.try(:first) || create(:organization) }
    issued_at { nil }

    factory :manufacturer_donation do
      manufacturer
      source { Donation::SOURCES[:manufacturer] }
    end

    factory :product_drive_donation do
      product_drive
      product_drive_participant
      source { Donation::SOURCES[:product_drive] }
    end

    factory :donation_site_donation do
      donation_site
      source { Donation::SOURCES[:donation_site] }
    end

    trait :with_items do
      storage_location do
        create :storage_location, :with_items,
               item: item || create(:item, value_in_cents: 100),
               organization: organization
      end
      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |donation, evaluator|
        event_item = View::Inventory.new(donation.organization_id)
          .items_for_location(donation.storage_location_id)
          .first
          &.db_item
        item = evaluator.item || event_item || create(:item)
        donation.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: donation)
      end

      after(:create) do |instance, evaluator|
        evaluator.storage_location.increase_inventory(instance.line_item_values)
        DonationEvent.publish(instance)
      end
    end
  end
end
