# == Schema Information
#
# Table name: items
#
#  id              :integer          not null, primary key
#  name            :string
#  category        :string
#  created_at      :datetime
#  updated_at      :datetime
#  barcode_count   :integer
#  organization_id :integer
#

RSpec.describe Item, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:item, organization_id: nil)).not_to be_valid
    end
    it "requires a unique name" do
      item = create(:item)
      expect(build(:item, name: nil)).not_to be_valid
      expect(build(:item, name: item.name)).not_to be_valid
    end
  end

  context "Filtering >" do
    it "can filter" do
      expect(subject.class).to respond_to :filter
    end

    it "->in_category returns all items in the provided category" do
      create(:item, category: "same")
      create(:item, category: "not same")
      expect(Item.in_category('same').length).to eq(1)
    end

    it "->in_same_category_as returns all items in the same category other than the provided item" do
      item = create(:item, name: "Foo", category: "same")
      other = create(:item, name: "Bar", category: "same")
      create(:item, category: "not same")
      result = Item.in_same_category_as(item)
      expect(result.length).to eq(1)
      expect(result.first).to eq(other)
    end
  end

  context "Methods >" do
    describe "categories" do
      it "returns a list of all categories, unique" do
        item = create(:item, category: "same")
        create(:item, category: "different")
        result = Item.categories
        expect(result.length).to eq(10)
      end

      it "returns the list of categories alphabetized" do
        Item.delete_all
        item1 = create(:item, category: "one")
        item2 = create(:item, category: "two")
        item3 = create(:item, category: "three")
        alphabetized_list = [ item1, item3, item2 ]
        result = Item.categories
        expect(result.map(&:category)).to eq(alphabetized_list.map(&:category))
      end
    end

    describe "storage_locations_containing" do
      it "retrieves all storage locations that contain an item" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item: item, item_quantity: 10)
        create(:storage_location)
        expect(Item.storage_locations_containing(item).first).to eq(storage_location)
      end
    end

    describe "barcodes_for" do
      it "retrieves all BarcodeItems associated with an item" do
        item = create(:item)
        barcode_item = create(:barcode_item, item: item)
        create(:barcode_item)
        expect(Item.barcodes_for(item).first).to eq(barcode_item)
      end
    end
    describe "barcoded_items >" do
      it "returns a collection of items that have barcodes associated with them" do
        create_list(:item, 3)
        create(:barcode_item, item: Item.first)
        create(:barcode_item, item: Item.last)
        expect(Item.barcoded_items.length).to eq(2)
      end
    end
  end

  context "Alphabetized Scope >" do
    it "retrieves items in alphabetical order" do
      Item.delete_all
      item_c = create(:item, name: "C")
      item_b = create(:item, name: "B")
      item_a = create(:item, name: "A")
      alphabetized_list = [item_a.name, item_b.name, item_c.name]
      expect(Item.alphabetized.count).to eq(3)
      expect(Item.alphabetized.map(&:name)).to eq(alphabetized_list)
    end
  end

  context "Callbacks >" do
    describe "when DIAPER_PARTNER_URL is present" do
      let(:diaper_partner_url) { "http://diaper.partner.io" }
      let(:callback_url) { "#{diaper_partner_url}/items" }

      before do
        stub_env "DIAPER_PARTNER_URL", diaper_partner_url
        stub_env "DIAPER_PARTNER_SECRET_KEY", "secretkey123"
        stub_request :post, callback_url
      end

      it "notifies the Diaper Partner app" do
        item = create :item
        headers = {
          "Authorization" => /APIAuth diaperbase:.*/,
          "Content-Type" => "application/x-www-form-urlencoded"
        }
        body = URI.encode_www_form item.attributes
        expect(WebMock).to have_requested(:post, callback_url).
          with(headers: headers, body: body).once
      end
    end
  end
end
