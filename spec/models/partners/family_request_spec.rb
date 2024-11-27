RSpec.describe Partners::FamilyRequest do
  describe "Partners::FamilyRequest.new_with_attrs" do
    it "creates a new FamilyRequest with attributes" do
      attributes = [{item_id: 1, person_count: 3}]
      request = Partners::FamilyRequest.new_with_attrs(attributes)

      expect(request.items.length).to eq(1)
      expect(request.items.first.item_id).to eq(1)
      expect(request.items.first.person_count).to eq(3)
    end
  end

  describe "#items_attributes=" do
    let(:item_attributes) { {"0" => {item_id: 1, person_count: 2}, "1" => {item_id: 2, person_count: 3}} }
    let(:family_request) { Partners::FamilyRequest.new({}) }

    it "assigns items based on given attributes" do
      family_request.items_attributes = item_attributes
      expect(family_request.items.length).to eq(2)
      expect(family_request.items.first.item_id).to eq(1)
      expect(family_request.items.first.person_count).to eq(2)
      expect(family_request.items.last.item_id).to eq(2)
      expect(family_request.items.last.person_count).to eq(3)
    end

    it "creates instances of Item with correct attributes" do
      family_request.items_attributes = item_attributes
      expect(family_request.items.first).to be_an_instance_of(Partners::FamilyRequest::Item)
      expect(family_request.items.last).to be_an_instance_of(Partners::FamilyRequest::Item)
    end

    it "overrides existing items" do
      family_request = Partners::FamilyRequest.new({}, initial_items: 6)
      expect(family_request.items.length).to eq(6)

      family_request.items_attributes = item_attributes
      expect(family_request.items.length).to eq(2)
      expect(family_request.items.first.item_id).to eq(1)
      expect(family_request.items.first.person_count).to eq(2)
      expect(family_request.items.last.item_id).to eq(2)
      expect(family_request.items.last.person_count).to eq(3)
    end
  end
end
