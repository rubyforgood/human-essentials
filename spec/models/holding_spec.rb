# == Schema Information
#
# Table name: holdings
#
#  id           :integer          not null, primary key
#  quantity     :integer
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  item_id      :integer
#

require "rails_helper"

RSpec.describe Holding, type: :model do
	describe "quantity" do
		it "is required" do
			holding = build(:holding, quantity: nil)
			expect(holding).not_to be_valid
		end
		it "is an integer" do
			holding = build(:holding, quantity: 'aaa')
			expect(holding).not_to be_valid
		end
		it "is not a negative number" do
			holding = build(:holding, quantity: -1)
			expect(holding).not_to be_valid
		end
	end
end
