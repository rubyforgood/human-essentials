# == Schema Information
#
# Table name: distributions
#
#  id           :integer          not null, primary key
#  comment      :text
#  created_at   :datetime
#  updated_at   :datetime
#  inventory_id :integer
#  partner_id   :integer
#



RSpec.describe Distribution, type: :model do
  context "Validations >" do
  	it "requires an inventory" do
      expect(build(:distribution, inventory: nil)).not_to be_valid
  	end

    it "requires a partner" do
  	  expect(build(:distribution, partner: nil)).not_to be_valid
  	end

    xit "ensures the associated containers are valid" do

  	end

    xit "ensures that any included items are found in the associated inventory" do
  	end
  end

  context "Methods >" do
    before(:each) do
      @distribution = create(:distribution)
      @first = create(:item, name: "AAA", category: "Foo")
      @last = create(:item, name: "ZZZ", category: "Bar")
    end

  	it "quantities_by_category" do
      @distribution.containers << create(:container, item: @first, quantity: 5)
      @distribution.containers << create(:container, item: @last, quantity: 10)
      @distribution.containers << create(:container, item: create(:item, category: "Foo"), quantity: 10)
      expect(@distribution.quantities_by_category).to eq({"Bar" => 10, "Foo" => 15})
  	end

  	it "sorted_containers" do
      c1 = create(:container, item: @first)
      c2 = create(:container, item: @last)
      @distribution.containers << c1
      @distribution.containers << c2
      expect(@distribution.sorted_containers.to_a).to match_array [c1,c2]
  	end
    
  	it "total_quantity" do
  		@distribution.containers << create(:container, item: @first, quantity: 5)
      @distribution.containers << create(:container, item: @last, quantity: 10)
      expect(@distribution.total_quantity).to eq(15)
  	end
  end
end
