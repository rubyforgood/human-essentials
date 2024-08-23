# == Schema Information
#
# Table name: product_drives
#
#  id              :bigint           not null, primary key
#  end_date        :date
#  name            :string
#  start_date      :date
#  virtual         :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#

RSpec.describe ProductDrive, type: :model do
  let(:organization) { create(:organization) }
  let(:product_drive) { create(:product_drive, organization: organization) }
  let!(:donation) { create(:donation, :with_items, item_quantity: 7, product_drive: product_drive) }
  let!(:donation2) { create(:donation, :with_items, item_quantity: 9, product_drive: product_drive) }
  let!(:extra_line_item) { create(:line_item, itemizable: donation, quantity: 4) }

  it "calculates donation quantity" do
    expect(product_drive.donation_quantity).to eq 20
  end

  it "calculates in-kind value" do
    expect(product_drive.in_kind_value).to be_a Integer
  end

  it "calculates donation quantity by date" do
    create(:donation, :with_items, item_quantity: 2, product_drive: product_drive, issued_at: '26-01-2023')
    expect(product_drive.donation_quantity_by_date(Time.zone.parse('23/01/2023')..Time.zone.parse('26/01/2023')))
      .to eq 2
  end

  it "calculates and returns all donated organization item quantities by name and date" do
    # an organization must have an item to be able to list it with item_quantities_by_name_and_date
    item = create(:item, organization: organization)

    create(:donation, :with_items, item: item, item_quantity: 2, product_drive: product_drive, issued_at: '26-01-2023')

    result = product_drive.item_quantities_by_name_and_date(Time.zone.parse('23/01/2023')..Time.zone.parse('26/01/2023'))

    # result contains donation, donation2, extra_line_item, created donation
    # [0, 0, 0, 2] since only created donation falls within the date range
    # everything else has current date for issued_at
    expect(result.length).to eq(4) # donation, donation2, extra_line_item, created donation
    expect(result.count(2)).to eq(1) # items with 2 quantity: created donation
    expect(result.count(0)).to eq(3) # items with 0 quantity: donation, donation2, extra_line_item
  end

  it "calculates and returns all donated organization item quantities by category and date" do
    item_category_1 = create(:item_category, id: 1)
    item_category_2 = create(:item_category, id: 2)
    item_1 = create(:item, name: "item_1", item_category_id: item_category_1.id)
    item_2 = create(:item, name: "item_2", item_category_id: item_category_2.id)
    donation = create(:donation, product_drive: product_drive, issued_at: '26-01-2023')
    line_item_1 = create(:line_item, itemizable: donation, item: item_1, quantity: 4)
    line_item_2 = create(:line_item, itemizable: donation, item: item_2, quantity: 5)

    donation.line_items << line_item_1
    donation.line_items << line_item_2

    result = product_drive.donation_quantity_by_date(Time.zone.parse('23/01/2023')..Time.zone.parse('26/01/2023'), 1)
    expect(result).to eq(4)
  end

  describe "validations" do
    it { expect(build(:product_drive, name: nil)).not_to be_valid }
    it { expect(build(:product_drive, start_date: nil)).not_to be_valid }
    it { expect(build(:product_drive, start_date: '2020-12-17', end_date: '2019-12-19')).not_to be_valid }
  end

  describe "associations" do
    let!(:product_drive_participant) { create(:product_drive_participant) }
    let!(:donation) { create(:product_drive_donation, product_drive_participant: product_drive_participant) }
    let!(:product_drive2) { create(:product_drive) }
    let!(:donation2) { create(:donation, :with_items, item_quantity: 7, product_drive: product_drive2, product_drive_participant: product_drive_participant) }

    subject { create(:product_drive) }

    it "has_many donations" do
      subject.donations << donation

      expect(subject.donations).to include(donation)
    end
    it "has_many product_drive_participants through donations" do
      subject.donations << donation
      is_expected.to have_many(:product_drive_participants).through(:donations)
      expect(subject.product_drive_participants).to include(donation.product_drive_participant)
    end
  end

  describe "distinct_items" do
    let!(:item_category) { create(:item_category, id: 1) }
    let!(:item_1) { create(:item, name: "item_1", item_category_id: 1) }
    let!(:item_2) { create(:item, name: "item_2", item_category_id: 1) }
    let!(:item_3) { create(:item, name: "item_3") }
    let!(:item_4) { create(:item, name: "item_4") }

    it("counts the items correctly for 1 donation with multiple items") do
      product_drive = create(:product_drive)
      donation_1 = create(:donation, product_drive: product_drive)

      line_item_1_1 = create(:line_item, itemizable: donation_1, item: item_1, quantity: 4)
      line_item_1_2 = create(:line_item, itemizable: donation_1, item: item_2, quantity: 5)
      line_item_1_3 = create(:line_item, itemizable: donation_1, item: item_3, quantity: 6)

      donation_1.line_items << line_item_1_1
      donation_1.line_items << line_item_1_2
      donation_1.line_items << line_item_1_3
      expect(product_drive.distinct_items_count).to eq 3
    end

    it("doesn't double_count the items if there are two donations for the same item") do
      product_drive = create(:product_drive)
      donation_1 = create(:donation, product_drive: product_drive)
      donation_2 = create(:donation, product_drive: product_drive)
      line_item_1_1 = create(:line_item, itemizable: donation_1, item: item_1, quantity: 4)
      line_item_2_1 = create(:line_item, itemizable: donation_2, item: item_1, quantity: 75)

      donation_1.line_items << line_item_1_1
      donation_2.line_items << line_item_2_1
      expect(product_drive.distinct_items_count).to eq 1
    end

    it("counts the distinct items correctly in overlapping donations") do
      product_drive = create(:product_drive)
      donation_1 = create(:donation, product_drive: product_drive)
      donation_2 = create(:donation, product_drive: product_drive)
      line_item_1_1 = create(:line_item, itemizable: donation_1, item: item_1, quantity: 4)
      line_item_1_2 = create(:line_item, itemizable: donation_1, item: item_2, quantity: 5)
      line_item_2_1 = create(:line_item, itemizable: donation_2, item: item_1, quantity: 75)
      line_item_2_4 = create(:line_item, itemizable: donation_2, item: item_4, quantity: 65)

      donation_1.line_items << line_item_1_1
      donation_1.line_items << line_item_1_2

      donation_2.line_items << line_item_2_1
      donation_2.line_items << line_item_2_4

      expect(product_drive.distinct_items_count).to eq 3
    end

    it("counts the distinct items correctly by given date") do
      product_drive = create(:product_drive)
      donation_within_date = create(:donation, product_drive: product_drive, issued_at: '26-01-2023')
      donation_out_of_date = create(:donation, product_drive: product_drive, issued_at: '20-01-2023')
      line_item_1 = create(:line_item, itemizable: donation_within_date, item: item_1, quantity: 4)
      line_item_2 = create(:line_item, itemizable: donation_out_of_date, item: item_2, quantity: 5)

      donation_within_date.line_items << line_item_1
      donation_out_of_date.line_items << line_item_2

      expect(product_drive.distinct_items_count_by_date(Time.zone.parse('23/01/2023')..Time.zone.parse('26/01/2023')))
        .to eq(1)
    end

    it("counts the distinct items correctly by given category") do
      product_drive = create(:product_drive)
      donation_within_date = create(:donation, product_drive: product_drive, issued_at: '26-01-2023')
      donation_out_of_date = create(:donation, product_drive: product_drive, issued_at: '20-01-2023')
      line_item_1 = create(:line_item, itemizable: donation_within_date, item: item_1, quantity: 4)
      line_item_2 = create(:line_item, itemizable: donation_within_date, item: item_2, quantity: 5)
      line_item_3 = create(:line_item, itemizable: donation_within_date, item: item_3, quantity: 6)
      line_item_4 = create(:line_item, itemizable: donation_out_of_date, item: item_1, quantity: 7)

      donation_within_date.line_items << line_item_1
      donation_within_date.line_items << line_item_2
      donation_within_date.line_items << line_item_3
      donation_out_of_date.line_items << line_item_4

      expect(product_drive.distinct_items_count_by_date(Time.zone.parse('23/01/2023')..Time.zone.parse('26/01/2023'), 1))
        .to eq(2)
    end
  end

  describe "scopes" do
    describe ".by_name" do
      let!(:product_drive1) { create(:product_drive, name: 'some_name') }
      let!(:product_drive2) { create(:product_drive, name: 'other_name') }

      it "returns the product_drive with name some_name" do
        expect(described_class.by_name('some_name')).to include(product_drive1)
      end

      it "does not return other_name" do
        expect(described_class.by_name('some_name')).not_to include(product_drive2)
      end
    end

    describe ".by_item_category_id" do
      let!(:item_category) { create(:item_category, id: 1) }
      let!(:item) { create(:item, name: "item_1", item_category_id: 1) }
      let!(:product_drive1) { create(:product_drive, name: 'some_name') }
      let!(:product_drive2) { create(:product_drive, name: 'other_name') }

      it "returns the product_drive with name some_name" do
        donation = create(:donation, product_drive: product_drive1)
        line_item = create(:line_item, itemizable: donation, item: item, quantity: 4)

        donation.line_items << line_item

        expect(described_class.by_item_category_id(1)).to include(product_drive1)
      end

      it "does not return other_name" do
        donation = create(:donation, product_drive: product_drive1)
        line_item = create(:line_item, itemizable: donation, item: item, quantity: 4)

        donation.line_items << line_item

        expect(described_class.by_item_category_id(1)).not_to include(product_drive2)
      end
    end

    describe ".within_date_range" do
      let(:start_date) { "2019-12-17" }
      let(:end_date) { "2019-12-19" }
      let(:other_start_date) { "2016-11-1" }
      let(:other_end_date) { "2017-9-12" }
      let!(:product_drive1) { create(:product_drive, start_date: start_date, end_date: end_date) }
      let!(:product_drive2) { create(:product_drive, start_date: other_start_date, end_date: other_end_date) }

      it "returns the product drive 1" do
        expect(described_class.within_date_range("#{start_date} - #{end_date}")).to include(product_drive1)
      end

      it "does not include product drive 2" do
        expect(described_class.within_date_range("#{start_date} - #{end_date}")).not_to include(product_drive2)
      end
    end
  end

  describe ".search_date_range" do
    let(:range_date) { "2019-12-17 - 2019-12-19" }

    subject { described_class.search_date_range(range_date) }

    it { is_expected.to eq(start_date: "2019-12-17", end_date: "2019-12-19") }
  end

  describe "donation_source_view" do
    it "returns formatted text" do
      expect(product_drive.donation_source_view).to eq("Test Drive (product drive)")
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
