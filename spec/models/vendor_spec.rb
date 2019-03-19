# == Schema Information
#
# Table name: vendors
#
#  id              :bigint(8)        not null, primary key
#  contact_name    :string
#  email           :string
#  phone           :string
#  comment         :string
#  organization_id :integer
#  address         :string
#  business_name   :string
#  latitude        :float
#  longitude       :float
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require "rails_helper"

RSpec.describe Vendor, type: :model do
  it_behaves_like "provideable"

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been bought from this vendor" do
        vendor = create(:vendor)
        create(:purchase, :with_items, item_quantity: 10, amount_spent: 1, vendor: vendor)
        expect(vendor.volume).to eq(10)
      end
    end
  end
end
