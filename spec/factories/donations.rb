# == Schema Information
#
# Table name: donations
#
#  id                  :integer          not null, primary key
#  source              :string
#  completed           :boolean          default("false")
#  dropoff_location_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#  inventory_id        :integer
#  comment             :text
#  organization_id     :integer
#

FactoryGirl.define do
  factory :donation do
    dropoff_location
    source "Donation"
    comment "It's a fine day for diapers."
    inventory
    organization
    # completed false

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
