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
#

FactoryBot.define do
  factory :donation do
    donation_site
    diaper_drive_participant
    source { Donation::SOURCES[:misc] }
    comment "It's a fine day for diapers."
    storage_location
    organization { Organization.try(:first) || create(:organization) }
    issued_at nil

    trait :with_items do
      storage_location { create :storage_location, :with_items, item: item || create(:item), organization: organization }

      transient do
        item_quantity 100
        item nil
      end

      after(:build) do |instance, evaluator|
        item = evaluator.item || instance.storage_location.inventory_items.first.item
        instance.line_items << build(:line_item, quantity: evaluator.item_quantity, item: item)
      end
    end
  end
end
