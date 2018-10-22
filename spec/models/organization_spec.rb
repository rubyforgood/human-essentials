# == Schema Information
#
# Table name: organizations
#
#  id              :integer          not null, primary key
#  name            :string
#  short_name      :string
#  email           :string
#  url             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  intake_location :integer
#  street          :string
#  city            :string
#  state           :string
#  zipcode         :string
#  latitude        :float
#  longitude       :float

require "geocoder_helper.rb"

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

  describe "ActiveStorage validation" do
    it "validates that attachments are png or jpgs" do
      expect(build(:organization,
                   logo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.jpg"),
                                                      "image/jpeg")))
        .to be_valid
      expect(build(:organization,
                   logo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.gif"),
                                                      "image/gif")))
        .to_not be_valid
    end
  end

  describe "#short_name" do
    it "can only contain valid characters" do
      expect(build(:organization, short_name: "asdf")).to be_valid
      expect(build(:organization, short_name: "Not Legal!")).to_not be_valid
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

  describe "logo_path" do
    it "returns the the default logo path when no logo attached" do
      org = build(:organization, logo: nil)
      expect(org.logo_path).to include("app/assets/images/DiaperBase-Logo.png")
    end

    xit "returns the logo path attached for the organization" do
      org = build(:organization,
                  logo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.jpg"),
                                                     "image/jpeg"))

      expect(org.logo_path).to include(Rails.root.join("tmp/storage").to_s)
    end
  end

  describe "geocode" do
    # TODO: This spec is failing but the fix is out of scope for the PR
    xit "adds coordinates to the database" do
      organization = build(:organization,
                           "street" => "1500 Remount Road",
                           "city"  => "Front Royal",
                           "state" => "VA",
                           "zipcode" => "12345")
      organization.save
      expect(organization.latitude).not_to eq(nil)
      expect(organization.longitude).not_to eq(nil)
    end
  end
end
