# == Schema Information
#
# Table name: items
#
#  id                             :integer          not null, primary key
#  name                           :string
#  category                       :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  barcode_count                  :integer
#  organization_id                :integer
#  active                         :boolean          default(TRUE)
#  partner_key                    :string
#  value_in_cents                 :integer          default(0)
#  on_hand_minimum_quantity       :integer          default(0)
#  on_hand_recommended_quantity   :integer
#  package_size                   :integer
#  distribution_quantity          :integer
#

RSpec.describe Item, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:item, organization_id: nil)).not_to be_valid
    end
    it "requires a Base Item base" do
      expect(build(:item, partner_key: nil)).not_to be_valid
    end
    it "requires a unique name" do
      item = create(:item)
      expect(build(:item, name: nil)).not_to be_valid
      expect(build(:item, name: item.name)).not_to be_valid
    end
  end

  context "Filtering >" do
    it "can filter" do
      expect(subject.class).to respond_to :class_filter
    end

    it "->by_size returns all items with the same size, per their BaseItem parent" do
      size4 = create(:base_item, size: "4")
      size_z = create(:base_item, size: "Z")
      create(:item, base_item: size4)
      create(:item, base_item: size4)
      create(:item, base_item: size_z)
      expect(Item.by_size("4").length).to eq(2)
    end

    it "->alphabetized retrieves items in alphabetical order" do
      Item.delete_all
      item_c = create(:item, name: "C")
      item_b = create(:item, name: "B")
      item_a = create(:item, name: "A")
      alphabetized_list = [item_a.name, item_b.name, item_c.name]
      expect(Item.alphabetized.count).to eq(3)
      expect(Item.alphabetized.map(&:name)).to eq(alphabetized_list)
    end

    it "->active shows items that are still active" do
      Item.delete_all
      inactive_item = create(:line_item, :purchase).item
      item = create(:item)
      inactive_item.destroy
      expect(Item.active.to_a).to match_array([item])
    end

    describe "->by_base_item" do
      before(:each) do
        Item.delete_all
        @c1 = create(:base_item)
        create(:item, base_item: @c1, organization: @organization)
        create(:item, base_item: create(:base_item), organization: @organization)
      end
      it "shows the items for a particular base_item" do
        expect(Item.by_base_item(@c1).size).to eq(1)
      end
      it "can be chained to organization to constrain it to just 1 org's items" do
        create(:item, base_item: @c1, organization: create(:organization))
        expect(@organization.items.by_base_item(@c1).size).to eq(1)
      end
    end

    describe "->by_partner_key" do
      it "filters by partner key" do
        Item.delete_all
        c1 = create(:base_item, partner_key: "foo")
        c2 = create(:base_item, partner_key: "bar")
        create(:item, base_item: c1, partner_key: "foo", organization: @organization)
        create(:item, base_item: c2, partner_key: "bar", organization: @organization)
        expect(Item.by_partner_key("foo").size).to eq(1)
        expect(Item.active.size).to be > 1
      end
    end
  end

  context "Methods >" do
    describe "storage_locations_containing" do
      it "retrieves all storage locations that contain an item" do
        item = create(:item)
        storage_location = create(:storage_location, :with_items, item: item, item_quantity: 12)
        create(:storage_location)
        expect(Item.storage_locations_containing(item).first).to eq(storage_location)
      end
    end

    describe "barcodes_for" do
      it "retrieves all BarcodeItems associated with an item" do
        item = create(:item)
        barcode_item = create(:barcode_item, barcodeable: item)
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

    describe "has_history?" do
      it "identifies items that have been used previously" do
        no_history_item = create(:item)
        item_in_line_item = create(:line_item, :purchase).item
        item_in_inventory_item = create(:inventory_item).item
        item_in_barcodes = create(:barcode_item).barcodeable

        expect(no_history_item).not_to have_history
        expect(item_in_line_item).to have_history
        expect(item_in_inventory_item).to have_history
        expect(item_in_barcodes).to have_history
      end
    end

    describe "other?" do
      it "is true for items that are partner_key 'other'" do
        item = create(:item, base_item: BaseItem.first)
        other_item = create(:item, partner_key: "other")
        expect(item).not_to be_other
        expect(other_item).to be_other
      end
    end

    describe "destroy" do
      it "actually destroys an item that doesn't have history" do
        item = create(:item)
        expect { item.destroy }.to change { Item.count }.by(-1)
      end

      it "only hides an item that has history" do
        item = create(:line_item, :purchase).item
        expect { item.destroy }.to change { Item.count }.by(0).and change { Item.active.count }.by(-1)
        expect(item).not_to be_active
      end
    end

    describe "#reactivate!" do
      context "given an array of item ids" do
        let(:item_array) { create_list(:item, 2, :inactive).collect(&:id) }
        it "sets the active trait to true for all of them" do
          expect do
            Item.reactivate(item_array)
          end.to change { Item.active.size }.by(item_array.size)
        end
      end

      context "given a single item id" do
        let(:item_id) { create(:item).id }
        it "sets the active trait to true for that item" do
          expect do
            Item.reactivate(item_id)
          end.to change { Item.active.size }.by(1)
        end
      end
    end
  end

  describe "default_quantity" do
    it "should return 50 if column is not set" do
      expect(create(:item).default_quantity).to eq(50)
    end

    it "should return the value of distribution_quantity if it is set" do
      expect(create(:item, distribution_quantity: 75).default_quantity).to eq(75)
    end

    it "should return 0 if on_hand_minimum_quantity is not set" do
      expect(create(:item).on_hand_minimum_quantity).to eq(0)
    end

    it "should return the value of on_hand_minimum_quantity if it is set" do
      expect(create(:item, on_hand_minimum_quantity: 42).on_hand_minimum_quantity).to eq(42)
    end
  end

  describe "distribution_quantity and package size" do
    it "have nil values if an empty string is passed" do
      expect(create(:item, distribution_quantity: '').distribution_quantity).to be_nil
      expect(create(:item, package_size: '').package_size).to be_nil
    end
  end
end
