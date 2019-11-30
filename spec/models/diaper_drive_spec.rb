# == Schema Information
#
# Table name: diaper_drives
#
#  id         :bigint           not null, primary key
#  end_date   :date
#  name       :string
#  start_date :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe DiaperDrive, type: :model do
  let!(:diaper_drive) { create(:diaper_drive) }
  let!(:donation) { create(:donation, :with_items, item_quantity: 7, diaper_drive: diaper_drive) }
  let!(:donation_2) { create(:donation, :with_items, item_quantity: 9, diaper_drive: diaper_drive) }
  let!(:extra_line_item) { create(:line_item, itemizable: donation, quantity: 4) }

  it "calculates donation quantity" do
    expect(diaper_drive.donation_quantity).to eq 20
  end

  it "calculates in-kind value" do
    expect(diaper_drive.in_kind_value).to be_a Integer
  end
end
