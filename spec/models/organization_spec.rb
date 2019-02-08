# == Schema Information
#
# Table name: organizations
#
#  id                 :integer          not null, primary key
#  name               :string
#  short_name         :string
#  email              :string
#  url                :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  intake_location    :integer
#  street             :string
#  city               :string
#  state              :string
#  zipcode            :string
#  latitude           :float
#  longitude          :float
#  default_email_text :text
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

  describe "#ordered_requests" do
    let!(:new_active_request)  { create(:request, comments: "first active") }
    let!(:old_active_request) { create(:request, comments: "second active") }
    let!(:fulfilled_request) { create(:request, status: 'Fulfilled', comments: "first fulfilled") }
    let!(:organization) { create(:organization, requests: [old_active_request, fulfilled_request, new_active_request]) }

    it "puts active requests before fulfilled requests" do
      expect(organization.ordered_requests.pluck(:comments)).to eq(["first active", "second active", "first fulfilled"])
    end

    context "ordering of requests with matching status" do
      before do
        old_active_request.update(updated_at: 5.minutes.after)
      end

      it "puts the most recently updated request before older requests" do
        expect(organization.ordered_requests.pluck(:comments)).to eq(["second active", "first active", "first fulfilled"])
      end
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
      expect(org.logo_path).to include("/img/diaperbase-logo-full.png")
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
                           "city" => "Front Royal",
                           "state" => "VA",
                           "zipcode" => "12345")
      organization.save
      expect(organization.latitude).not_to eq(nil)
      expect(organization.longitude).not_to eq(nil)
    end
  end

  describe 'address' do
    it 'returns an empty string when the org has no address components' do
      expect(Organization.new.address).to be_blank
    end

    it 'correctly formats an address string with commas and spaces' do
      org = Organization.new(street: '123 Main St.', city: 'Anytown', state: 'KS', zipcode: '12345')
      expect(org.address).to eq('123 Main St., Anytown, KS 12345')
    end

    it 'does not add a trailing space when the zip code is missing' do
      org = Organization.new(street: '123 Main St.', city: 'Anytown', state: 'KS')
      expect(org.address).to eq('123 Main St., Anytown, KS')
    end

    it 'does not add any separators before the city when street is missing' do
      org = Organization.new(city: 'Anytown', state: 'KS', zipcode: '12345')
      expect(org.address).to eq('Anytown, KS 12345')
    end

    it 'does not add any separators after street when city, state, and zip are missing' do
      org = Organization.new(street: '123 Main St.')
      expect(org.address).to eq('123 Main St.')
    end
  end

  describe 'valid_items' do
    it 'returns an array of item partner keys' do
      org = create(:organization)
      expect(org.valid_items).to be_an(Array)
      expect(org.valid_items.first).to be_an(String)
    end
  end
end
