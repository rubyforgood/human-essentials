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
#  reminder_day    :integer
#  deadline_day    :integer
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

    describe "items" do
      before do
        organization.items.each_with_index do |item, index|
          (index + 1).times { LineItem.create!(quantity: rand(250..500), item: item, itemizable: Distribution.new) }
        end
      end
      describe ".during" do
        it "return ranking of all items" do
          ranking_items = organization.items.during('1950-01-01', '3000-01-01')
          expect(ranking_items.length).to eq(organization.items.length)
        end
      end
      describe ".during.top" do
        it "return just 3 elements" do
          ranking_items = organization.items.during('1950-01-01', '3000-01-01').top(3)
          expect(ranking_items.length).to eq(3)
        end
        it "return 3 most used items" do
          ranking_items = organization.items.during('1950-01-01', '3000-01-01').top(3)

          expect(ranking_items[0].amount).to eq(organization.items.length)
          expect(ranking_items[0].name).to eq(organization.items[organization.items.length - 1].name)

          expect(ranking_items[1].amount).to eq(organization.items.length - 1)
          expect(ranking_items[1].name).to eq(organization.items[organization.items.length - 2].name)

          expect(ranking_items[2].amount).to eq(organization.items.length - 2)
          expect(ranking_items[2].name).to eq(organization.items[organization.items.length - 3].name)
        end
      end
      describe ".during.bottom" do
        it "return just 3 elements" do
          ranking_items = organization.items.during('1950-01-01', '3000-01-01').bottom(3)
          expect(ranking_items.length).to eq(3)
        end
        it "return 3 least used items" do
          ranking_items = organization.items.during('1950-01-01', '3000-01-01').bottom(3)

          expect(ranking_items[0].amount).to eq(1)
          expect(ranking_items[0].name).to eq(organization.items[0].name)

          expect(ranking_items[1].amount).to eq(2)
          expect(ranking_items[1].name).to eq(organization.items[1].name)

          expect(ranking_items[2].amount).to eq(3)
          expect(ranking_items[2].name).to eq(organization.items[2].name)
        end
      end
    end
  end

  describe "seed_items" do
    it "loads the base items into Item records" do
      base_items_count = BaseItem.count
      Organization.seed_items(organization)
      expect(organization.items.count).to eq(base_items_count)
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
    let!(:fulfilled_request) { create(:request, :fulfilled, comments: "first fulfilled") }
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

    it "returns the logo path attached for the organization" do
      org = build(:organization,
                  logo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/logo.jpg"),
                                                     "image/jpeg"))

      expect(org.logo_path).to include(Rails.root.join("tmp/storage").to_s)
    end
  end

  describe "geocode" do
    it "adds coordinates to the database" do
      pending("TODO: This spec is failing but the fix is out of scope for the PR")
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
      item = organization.items.first
      expected = { name: item.name, id: item.id, partner_key: item.partner_key }
      expect(organization.valid_items.count).to eq(organization.items.count)
      expect(organization.valid_items).to include(expected)
    end
  end
  describe 'reminder_day' do
    it "can only contain numbers 1-14" do
      expect(build(:organization, reminder_day: 14)).to be_valid
      expect(build(:organization, reminder_day: 1)).to be_valid
      expect(build(:organization, reminder_day: 0)).to_not be_valid
      expect(build(:organization, reminder_day: -5)).to_not be_valid
      expect(build(:organization, reminder_day: 15)).to_not be_valid
    end
  end
  describe 'deadline_day' do
    it "can only contain numbers 1-28" do
      expect(build(:organization, deadline_day: 28)).to be_valid
      expect(build(:organization, deadline_day: 0)).to_not be_valid
      expect(build(:organization, deadline_day: -5)).to_not be_valid
      expect(build(:organization, deadline_day: 29)).to_not be_valid
    end
  end
  describe 'deadline_after_reminder' do
    it "deadline must be after reminder" do
      expect(build(:organization, reminder_day: 14, deadline_day: 28)).to be_valid
      expect(build(:organization, reminder_day: 28, deadline_day: 14)).to_not be_valid
    end
  end
end
