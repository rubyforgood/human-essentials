# == Schema Information
#
# Table name: distributions
#
#  id                  :integer          not null, primary key
#  comment             :text
#  created_at          :datetime
#  updated_at          :datetime
#  storage_location_id :integer
#  partner_id          :integer
#  organization_id     :integer
#  issued_at           :datetime
#

RSpec.describe Distribution, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:distribution, organization: nil)).not_to be_valid
    end
    it "requires a storage location" do
      expect(build(:distribution, storage_location: nil)).not_to be_valid
    end

    it "requires a partner" do
      expect(build(:distribution, partner: nil)).not_to be_valid
    end

    # TODO: distribution_spec: "ensures the associated line_items are valid"
    xit "ensures the associated line_items are valid" do
  	end

    # TODO: distribution_spec: "ensures that any included items are found in the associated storage location"
    xit "ensures that any included items are found in the associated storage location" do
    end
  end

  context "Scopes >" do
    describe "during >" do
      it "returns all distrbutions created between two dates" do
        # The models should default to assigning the created_at time to the issued_at
        create(:distribution, created_at: Date.today)
        # but just for fun we'll force one in the past within the range
        create(:distribution, issued_at: Date.yesterday)
        # and one outside the range
        create(:distribution, issued_at: 1.year.ago)
        
        expect(Distribution.during(1.month.ago..Date.tomorrow).size).to eq(2)
      end
    end
  end

  context "Callbacks >" do
    it "initializes the issued_at field to default to created_at if it wasn't explicitly set" do
      yesterday = 1.day.ago
      today = Date.today
      expect(create(:distribution, created_at: yesterday, issued_at: today).issued_at).to eq(today)
      expect(create(:distribution, created_at: yesterday).issued_at).to eq(yesterday)
    end
  end

  context "Methods >" do
    before(:each) do
      @distribution = create(:distribution)
      @first = create(:item, name: "AAA", category: "Foo")
      @last = create(:item, name: "ZZZ", category: "Bar")
    end

    it "quantities_by_category" do
      @distribution.line_items << create(:line_item, item: @first, quantity: 5)
      @distribution.line_items << create(:line_item, item: @last, quantity: 10)
      @distribution.line_items << create(:line_item, item: create(:item, category: "Foo"), quantity: 10)
      expect(@distribution.quantities_by_category).to eq({"Bar" => 10, "Foo" => 15})
    end

    it "sorted_line_items" do
      c1 = create(:line_item, item: @first)
      c2 = create(:line_item, item: @last)
      @distribution.line_items << c1
      @distribution.line_items << c2
      expect(@distribution.sorted_line_items.to_a).to match_array [c1,c2]
  	end

    it "total_quantity" do
      @distribution.line_items << create(:line_item, item: @first, quantity: 5)
      @distribution.line_items << create(:line_item, item: @last, quantity: 10)
      expect(@distribution.total_quantity).to eq(15)
    end
  end
end
