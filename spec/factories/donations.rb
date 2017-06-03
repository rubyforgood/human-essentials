# == Schema Information
#
# Table name: donations
#
#  id                          :integer          not null, primary key
#  source                      :string
#  dropoff_location_id         :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  storage_location_id         :integer
#  comment                     :text
#  organization_id             :integer
#  diaper_drive_participant_id :integer
#  issued_at                   :datetime
#

FactoryGirl.define do
  factory :donation do
    dropoff_location
    diaper_drive_participant
    source { Donation::SOURCES[:misc] }
    comment "It's a fine day for diapers."
    storage_location
    organization { Organization.try(:first) || create(:organization) }
    issued_at nil

    transient do
      item_quantity 10
      item_id nil
    end

    trait :with_item do
      after(:create) do |instance, evaluator|
        item_id = (evaluator.item_id.nil?) ? create(:item).id : evaluator.item_id
        instance.line_items << create(:line_item, :donation, quantity: evaluator.item_quantity, item_id: item_id)
      end
    end
  end
end
