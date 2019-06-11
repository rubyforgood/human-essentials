# == Schema Information
#
# Table name: donations
#
#  id                          :bigint(8)        not null, primary key
#  source                      :string
#  donation_site_id            :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#  issued_at                   :datetime
#  money_raised                :integer
#  manufacturer_id             :bigint(8)
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

    factory :diaper_drive_donation do
      diaper_drive_participant
      source { Donation::SOURCES[:diaper_drive] }
    end

    factory :donation_site_donation do
      donation_site
      source { Donation::SOURCES[:donation_site] }
    end

    trait :with_items do
      storage_location { create :storage_location, :with_items, item: item || create(:item), organization: organization }

      transient do
        item_quantity { 100 }
        item { nil }
      end

      after(:build) do |donation, evaluator|
        item = evaluator.item || donation.storage_location.inventory_items.first.item
        donation.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item, itemizable: donation)
      end
    end
  end
end
