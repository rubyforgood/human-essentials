# == Schema Information
#
# Table name: tickets
#
#  id           :integer          not null, primary key
#  comment      :text
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  partner_id   :integer
#

require "rails_helper"

RSpec.describe Ticket, type: :model do
  context "Validations >" do
  	it "requires an inventory" do
      expect(build(:ticket, inventory: nil)).not_to be_valid
  	end
  	it "requires a partner" do
  	  expect(build(:ticket, partner: nil)).not_to be_valid
  	end
  	xit "ensures the associated containers are valid" do
      
  	end
  	xit "ensures that any included items are found in the associated inventory" do
  	end
  end

  context "Methods >" do
  	describe "quantities_by_category" do
  	  pending "responds with breakdown of different categories and how much is in each one"
  	end
  	describe "sorted_containers" do
  		pending "lists all containers, sorted by item name"
  	end
  	describe "total_quantity" do
  		pending "shows the total of all items found in all containers"
  	end
  end
end
