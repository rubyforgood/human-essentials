# == Schema Information
#
# Table name: organizations
#
#  id                :bigint(8)        not null, primary key
#  name              :string
#  short_name        :string
#  address           :text
#  email             :string
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  logo_file_name    :string
#  logo_content_type :string
#  logo_file_size    :integer
#  logo_updated_at   :datetime
#  intake_location   :integer
#  street            :string
#  city              :string
#  state             :string
#  zipcode           :string
#

RSpec.describe Organization, type: :model do
  let(:organization) { create(:organization) }
  context "Associations >" do
    describe "barcode_items" do
      before do
        BarcodeItem.delete_all
        create(:barcode_item, organization: organization)
        create(:global_barcode_item) # global
      end
      it "returns only this organization's barcodes, no globals" do
        expect(organization.barcode_items.count).to eq(1)
      end
      describe ".all" do
        it "includes global barcode items also" do
          expect(organization.barcode_items.all.count).to eq(2)
        end
      end
    end
  end

  describe "seed_items" do
    it "loads the canonical items into Item records" do
      canonical_items_count = CanonicalItem.count
      Organization.seed_items(organization)
      expect(organization.items.count).to eq(canonical_items_count)
    end
  end

  describe "paperclip validations" do
    it "validates that attachments are png or jpgs" do
      should validate_attachment_content_type(:logo)
        .allowing('image/png', 'image/jpg')
        .rejecting('text/plain', 'text/xml')
    end
  end

  describe "#short_name" do
    it "can only contain valid characters" do
      expect(build(:organization, short_name: 'asdf')).to be_valid
      expect(build(:organization, short_name: 'Not Legal!')).to_not be_valid
    end
  end

  describe "total_inventory" do
    it "returns a sum total of all inventory at all storage locations" do
      item = create(:item)
      create(:storage_location, :with_items, item: item, item_quantity: 100, organization: organization)
      create(:storage_location, :with_items, item: item, item_quantity: 150, organization: organization)
      expect(organization.total_inventory).to eq(250)
    end
    it "returns 0 if there is nothing" do
      expect(organization.total_inventory).to eq(0)
    end
  end
end
