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
	context "Validations >" do
	  describe "quantity >" do
	  	it "is required" do
	  	  expect(build(:holding, quantity: nil)).not_to be_valid
	  	end
	  	it "is numerical" do
	  	  expect(build(:holding, quantity: 'a')).not_to be_valid
	  	end
	  	it "is gte 0" do
	  		expect(build(:holding, quantity: -1)).not_to be_valid
	  		expect(build(:holding, quantity: 0)).to be_valid
	  	end
	  end
      it "requires an inventory association" do
      	expect(build(:holding, inventory_id: nil)).not_to be_valid
      end
      it "requires an item" do
      	expect(build(:holding, item_id: nil)).not_to be_valid
      end
	end

	it "initializes the quantity to 0 if it was not specified" do
		expect(Holding.new.quantity).to eq(0)
	end
end
