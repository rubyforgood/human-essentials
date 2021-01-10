# == Schema Information
#
# Table name: diaper_drives
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

require 'rails_helper'

RSpec.describe DiaperDrive, type: :model do
  let!(:diaper_drive) { create(:diaper_drive) }
  let!(:donation) { create(:donation, :with_items, item_quantity: 7, diaper_drive: diaper_drive) }
  let!(:donation2) { create(:donation, :with_items, item_quantity: 9, diaper_drive: diaper_drive) }
  let!(:extra_line_item) { create(:line_item, itemizable: donation, quantity: 4) }

  it "calculates donation quantity" do
    expect(diaper_drive.donation_quantity).to eq 20
  end

  it "calculates in-kind value" do
    expect(diaper_drive.in_kind_value).to be_a Integer
  end

  describe 'validations' do
    it { expect(build(:diaper_drive, name: nil)).not_to be_valid }
    it { expect(build(:diaper_drive, start_date: nil)).not_to be_valid }
    it { expect(build(:diaper_drive, start_date: '2020-12-17', end_date: '2019-12-19')).not_to be_valid }
  end

  describe 'associations' do
    let!(:donation) { create(:donation) }
    subject { create(:diaper_drive) }

    it 'has_many donations' do
      subject.donations << donation

      expect(subject.donations).to include(donation)
    end
  end

  describe 'scopes' do
    describe '.by_name' do
      let!(:diaper_drive1) { create(:diaper_drive, name: 'some_name') }
      let!(:diaper_drive2) { create(:diaper_drive, name: 'other_name') }

      it 'returns the diaper_drive with name some_name' do
        expect(described_class.by_name('some_name')).to include(diaper_drive1)
      end

      it 'does not return other_name' do
        expect(described_class.by_name('some_name')).not_to include(diaper_drive2)
      end
    end

    describe '.within_date_range' do
      let(:start_date) { '2019-12-17' }
      let(:end_date) { '2019-12-19' }
      let(:other_start_date) { '2016-11-1' }
      let(:other_end_date) { '2017-9-12' }
      let!(:diaper_drive1) { create(:diaper_drive, start_date: start_date, end_date: end_date) }
      let!(:diaper_drive2) { create(:diaper_drive, start_date: other_start_date, end_date: other_end_date) }

      it 'retuns the diaper drive 1' do
        expect(described_class.within_date_range("#{start_date} - #{end_date}")).to include(diaper_drive1)
      end

      it 'does not include diaper drive 2' do
        expect(described_class.within_date_range("#{start_date} - #{end_date}")).not_to include(diaper_drive2)
      end
    end
  end

  describe '.search_date_range' do
    let(:range_date) { '2019-12-17 - 2019-12-19' }

    subject { described_class.search_date_range(range_date) }

    it { is_expected.to eq(start_date: '2019-12-17', end_date: '2019-12-19') }
  end

  describe "donation_source_view" do
    it "returns formatted text" do
      expect(diaper_drive.donation_source_view).to eq("Test Drive (diaper drive)")
    end
  end
end
