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
    before(:each) do
      @ticket = create(:ticket)
      @first = create(:item, name: "AAA", category: "Foo")
      @last = create(:item, name: "ZZZ", category: "Bar")
    end

  	it "quantities_by_category" do
      @ticket.containers << create(:container, item: @first, quantity: 5)
      @ticket.containers << create(:container, item: @last, quantity: 10)
      @ticket.containers << create(:container, item: create(:item, category: "Foo"), quantity: 10)
      expect(@ticket.quantities_by_category).to eq({"Bar" => 10, "Foo" => 15})
  	end
  	it "sorted_containers" do
      c1 = create(:container, item: @first)
      c2 = create(:container, item: @last)
      @ticket.containers << c1
      @ticket.containers << c2
      expect(@ticket.sorted_containers.to_a).to match_array [c1,c2]
  	end
  	it "total_quantity" do
  		@ticket.containers << create(:container, item: @first, quantity: 5)
      @ticket.containers << create(:container, item: @last, quantity: 10)
      expect(@ticket.total_quantity).to eq(15)
  	end
  end
end
