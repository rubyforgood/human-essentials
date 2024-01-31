# == Schema Information
#
# Table name: organizations
#
#  id                                                 :integer          not null, primary key
#  city                                               :string
#  deadline_day                                       :integer
#  default_storage_location                           :integer
#  distribute_monthly                                 :boolean          default(FALSE), not null
#  email                                              :string
#  enable_child_based_requests                        :boolean          default(TRUE), not null
#  enable_individual_requests                         :boolean          default(TRUE), not null
#  enable_quantity_based_requests                     :boolean          default(TRUE), not null
#  intake_location                                    :integer
#  invitation_text                                    :text
#  latitude                                           :float
#  longitude                                          :float
#  name                                               :string
#  partner_form_fields                                :text             default([]), is an Array
#  reminder_day                                       :integer
#  repackage_essentials                               :boolean          default(FALSE), not null
#  short_name                                         :string
#  state                                              :string
#  street                                             :string
#  url                                                :string
#  use_single_step_invite_and_approve_partner_process :boolean          default(FALSE)
#  ytd_on_distribution_printout                       :boolean          default(TRUE), not null
#  zipcode                                            :string
#  created_at                                         :datetime         not null
#  updated_at                                         :datetime         not null
#  account_request_id                                 :integer
#  ndbn_member_id                                     :bigint
#

RSpec.describe Organization, type: :model do
  let(:organization) { create(:organization) }

  describe "validations" do
    it "validates that attachments are png or jpgs" do
      expect(build(:organization,
                   logo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.jpg"),
                                                      "image/jpeg")))
        .to be_valid
      expect(build(:organization,
                   logo: Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/logo.gif"),
                                                      "image/gif")))
        .to_not be_valid
    end

    it "validates that at least one distribution type is enabled" do
      expect(build(:organization, enable_child_based_requests: true)).to be_valid
      expect(build(:organization, enable_individual_requests: true)).to be_valid
      expect(build(:organization, enable_quantity_based_requests: true)).to be_valid
      expect(build(
        :organization,
        enable_child_based_requests: false,
        enable_individual_requests: false,
        enable_quantity_based_requests: false
      )).to_not be_valid
    end

    it "validates that short names are unique" do
      expect(create(:organization, short_name: "foo_bar")).to be_valid
      expect(build(:organization, short_name: "foo_bar")).to_not be_valid
    end

    it "validates that attachment file size is not higher than 1 MB" do
      fixture_path = File.join(Rails.root, 'spec', 'fixtures', 'files', 'logo.jpg')
      fixture_file = File.open(fixture_path)
      organization = build(:organization)

      allow(fixture_file).to receive(:size) { 2.megabytes }
      organization.logo.attach(io: fixture_file, filename: 'logo.jpg')

      expect(organization).to_not be_valid

      allow(fixture_file).to receive(:size) { 10.kilobytes }
      organization.logo.attach(io: fixture_file, filename: 'logo.jpg')

      expect(organization).to be_valid
    end
  end

  context "Associations >" do
    it { should have_many(:item_categories) }
    it { should belong_to(:ndbn_member).class_name("NDBNMember").optional }

    describe 'users' do
      subject { organization.users }
      let(:organization) { create(:organization) }

      context 'when a organizaton has a user that has two roles' do
        let(:user) { create(:user) }
        before do
          user.add_role(:admin, organization)
          user.add_role(:volunteer, organization)
        end

        it 'should returns users without duplications' do
          expect(subject).to eq([user])
        end
      end
    end

    it { is_expected.to have_many(:users).through(:roles) }

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

    describe "distributions" do
      describe "upcoming" do
        before do
          travel_to Time.zone.local(2019, 7, 3) # Wednesday
        end

        after do
          travel_back
        end

        it "retrieves the distributions scheduled for this week that have not yet happened" do
          wednesday_distribution_scheduled = create(:distribution, organization: @organization, state: :scheduled, issued_at: Time.zone.local(2019, 7, 3))
          create(:distribution, organization: @organization, state: :complete, issued_at: Time.zone.local(2019, 7, 3))
          sunday_distribution = create(:distribution, organization: @organization, state: :scheduled, issued_at: Time.zone.local(2019, 7, 7))
          upcoming_distributions = @organization.distributions.upcoming
          expect(upcoming_distributions).to match_array([wednesday_distribution_scheduled, sunday_distribution])
        end
      end
    end

    describe "items" do
      before do
        organization.items.each_with_index do |item, index|
          (index + 1).times { LineItem.create!(quantity: rand(250..500), item: item, itemizable: Distribution.new) }
        end
      end

      describe ".other" do
        it "returns all items for this organization designated 'other'" do
          create(:item, name: "SOMETHING", partner_key: "other", organization: organization)
          expect(organization.items.other.size).to eq(2)
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

  describe '#assign_attributes_from_account_request' do
    subject { organization.assign_attributes_from_account_request(account_request) }
    let(:organization) { Organization.new }
    let(:account_request) { FactoryBot.create(:account_request) }

    it 'should assign the proper attributes to the organization' do
      expect(subject.attributes).to include({
        name: account_request.organization_name,
        url: account_request.organization_website,
        email: account_request.email,
        account_request_id: account_request.id
      }.stringify_keys)
    end
  end

  describe 'after_create' do
    let(:account_request) { FactoryBot.create(:account_request) }
    it 'should update the state of the account request' do
      org = build(:organization, account_request: account_request)
      expect(account_request).not_to be_admin_approved
      org.save!
      expect(account_request.reload).to be_admin_approved
    end
  end

  describe ".seed_items" do
    context "when provided with an organization to seed" do
      it "loads the base items into Item records" do
        base_items_count = BaseItem.count
        Organization.seed_items(organization)
        expect(organization.items.count).to eq(base_items_count)
      end
    end

    context "when no organization is provided" do
      it "updates all organizations" do
        Organization.seed_items(@organization)
        second_organization = create(:organization)
        organization_item_count = @organization.items.size
        second_organization_item_count = second_organization.items.size
        create(:base_item, name: "Foo", partner_key: "foo")
        Organization.seed_items
        expect(@organization.items.size).to eq(organization_item_count + 1)
        expect(second_organization.items.size).to eq(second_organization_item_count + 1)
      end
    end
  end

  describe "#seed_items" do
    it "allows a single base item to be seeded" do
      organization # will auto-seed existing base items
      base_item = create(:base_item, name: "Foo", partner_key: "foo").to_h
      expect do
        organization.seed_items(base_item)
      end.to change { organization.items.size }.by(1)
    end

    it "allows a collection of items to be seeded" do
      organization # will auto-seed existing base items
      base_items = [create(:base_item, name: "Foo", partner_key: "foo").to_h, create(:base_item, name: "Bar", partner_key: "bar").to_h]
      expect do
        organization.seed_items(base_items)
      end.to change { organization.items.size }.by(2)
    end

    context "when given an item that already exists" do
      it "gracefully skips the item" do
        organization # will auto-seed existing base items
        base_item = create(:base_item, name: "Foo", partner_key: "foo")
        base_items = [base_item.to_h, BaseItem.first.to_h]
        expect do
          organization.seed_items(base_items)
        end.to change { organization.items.size }.by(1)
      end
    end

    context "when given an item name that already exists, but with an 'other' partner key" do
      it "updates the old item to use the new base item as its base" do
        organization # will auto-seed existing base items
        item = organization.items.create(name: "Foo", partner_key: "other")
        base_item = create(:base_item, name: "Foo", partner_key: "foo")
        base_items = [base_item.to_h, BaseItem.first.to_h]
        expect do
          organization.seed_items(base_items)
          item.reload
        end.to change { organization.items.size }.by(0).and change { item.partner_key }.to("foo")
      end
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

  describe 'is_active' do
    let!(:active_organization) { create(:organization) }
    let!(:inactive_organization) { create(:organization) }
    let!(:active_user) { create(:user, organization: active_organization, last_sign_in_at: 1.month.ago) }
    let!(:inactive_user) { create(:user, organization: inactive_organization, last_sign_in_at: 6.months.ago) }

    it 'returns active organizations' do
      expect(Organization.is_active).to contain_exactly(active_organization)
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

  describe "geocode" do
    it "adds coordinates to the database" do
      expect(organization.latitude).to be_a(Float)
      expect(organization.longitude).to be_a(Float)
    end
  end

  describe 'default storage location' do
    it 'returns nil when not set' do
      expect(Organization.new.default_storage_location).to be_nil
    end

    it 'associates the default storage location with a storage location' do
      storage_location = FactoryBot.build(:storage_location)
      org = Organization.new(default_storage_location: storage_location.id,
                             street: '123 Main St.',
                             city: 'Anytown',
                             state: 'KS',
                             zipcode: '12345')
      expect(org.default_storage_location).to eq(storage_location.id)
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
    it 'only shows active valid items' do
      intial_count = organization.valid_items.count
      organization.items.last.update(active: false)
      final_count = organization.valid_items.count
      expect(intial_count).to_not eq(final_count)
    end

    context 'with invisible items' do
      let!(:organization) { create(:organization, skip_items: true) }
      let!(:item1) { create(:item, organization: organization, active: true, visible_to_partners: true) }
      let!(:item2) { create(:item, organization: organization, active: true, visible_to_partners: false) }
      let!(:item3) { create(:item, organization: organization, active: false, visible_to_partners: true) }
      let!(:item4) { create(:item, organization: organization, active: false, visible_to_partners: false) }

      it 'only shows active and visible items' do
        expect(organization.valid_items).to eq([{ id: item1.id, partner_key: item1.partner_key, name: item1.name }])
      end
    end
  end

  describe 'from_email' do
    it 'returns email when present' do
      expect(organization.from_email).to eq(organization.email)
    end

    it 'returns admin email when not present' do
      org = create(:organization, email: nil)
      admin = create(:organization_admin, organization: org)
      expect(org.from_email).to eq(admin.email)
    end

    it "returns admin email when it's empty" do
      org = create(:organization, email: "")
      admin = create(:organization_admin, organization: org)
      expect(org.from_email).to eq(admin.email)
    end

    it "returns admin email when it's empty space" do
      org = create(:organization, email: " ")
      admin = create(:organization_admin, organization: org)
      expect(org.from_email).to eq(admin.email)
    end
  end

  describe 'reminder_day' do
    it "can only contain numbers 1-28" do
      expect(build(:organization, reminder_day: 28)).to be_valid
      expect(build(:organization, reminder_day: 1)).to be_valid
      expect(build(:organization, reminder_day: 0)).to_not be_valid
      expect(build(:organization, reminder_day: -5)).to_not be_valid
      expect(build(:organization, reminder_day: 29)).to_not be_valid
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

  describe 'earliest reporting year' do
    # re 2813 update annual report -- allowing an earliest reporting year will let us do system testing and staging for annual reports
    it 'is the organization created year if no associated data' do
      org = create(:organization)
      expect(org.earliest_reporting_year).to eq(org.created_at.year)
    end
    it 'is the year of the earliest of donation, purchase, or distribution if they are earlier ' do
      org = create(:organization)
      create(:donation, organization: org, issued_at: 1.year.from_now)
      create(:purchase, organization: org, issued_at: 1.year.from_now)
      create(:distribution, organization: org, issued_at: 1.year.from_now)
      expect(org.earliest_reporting_year).to eq(org.created_at.year)
      create(:donation, organization: org, issued_at: 5.years.ago)
      expect(org.earliest_reporting_year).to eq(5.years.ago.year)
      create(:purchase, organization: org, issued_at: 6.years.ago)
      expect(org.earliest_reporting_year).to eq(6.years.ago.year)
      create(:purchase, organization: org, issued_at: 7.years.ago)
      expect(org.earliest_reporting_year).to eq(7.years.ago.year)
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
