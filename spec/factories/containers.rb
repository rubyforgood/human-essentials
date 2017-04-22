# == Schema Information
#
# Table name: containers
#
#  id              :integer          not null, primary key
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#

FactoryGirl.define do
	factory :container do
		quantity 0
		item
        itemizable_type "Donation"
        itemizable_id { create(:donation).id }

		trait :donation do
		end

		trait :ticket do
			itemizable_type "Ticket"
			itemizable_id { create(:ticket).id }
		end
	end
end
