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

require "rails_helper"

RSpec.describe ProductDrive, type: :model, skip_seed: true do
  let!(:product_drive) { create(:product_drive) }
  let!(:donation) { create(:donation, :with_items, item_quantity: 7, product_drive: product_drive) }
  let!(:donation2) { create(:donation, :with_items, item_quantity: 9, product_drive: product_drive) }
  let!(:extra_line_item) { create(:line_item, itemizable: donation, quantity: 4) }

  it "calculates donation quantity" do
    expect(product_drive.donation_quantity).to eq 20
  end

  it "calculates in-kind value" do
    expect(product_drive.in_kind_value).to be_a Integer
  end

  describe "validations" do
    it { expect(build(:product_drive, name: nil)).not_to be_valid }
    it { expect(build(:product_drive, start_date: nil)).not_to be_valid }
    it { expect(build(:product_drive, start_date: '2020-12-17', end_date: '2019-12-19')).not_to be_valid }
  end

  describe "associations" do
    let!(:donation) { create(:donation) }
    subject { create(:product_drive) }

    it "has_many donations" do
      subject.donations << donation

      expect(subject.donations).to include(donation)
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
end
