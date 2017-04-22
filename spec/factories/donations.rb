# == Schema Information
#
# Table name: donations
#
#  id                  :integer          not null, primary key
#  source              :string
#  completed           :boolean          default(FALSE)
#  dropoff_location_id :integer
#  created_at          :datetime
#  updated_at          :datetime
#

FactoryGirl.define do
	factory :donation do
		dropoff_location
		source "Donation"
		# completed false

		transient do
			item_quantity 10
			item_id nil
		end

		trait :with_item do
			after(:create) do |instance, evaluator|
				item_id = (evaluator.item_id.nil?) ? create(:item).id : evaluator.item_id
				instance.containers << create(:container, :donation, quantity: evaluator.item_quantity, item_id: item_id)
			end
		end
	end
end
