# == Schema Information
#
# Table name: vendors
#
#  id              :bigint           not null, primary key
#  address         :string
#  business_name   :string
#  comment         :string
#  contact_name    :string
#  email           :string
#  latitude        :float
#  longitude       :float
#  phone           :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe Vendor, type: :model do
  it_behaves_like "provideable"

  context "Validations" do
    it "validates that a business name is present" do
      expect(build(:vendor, business_name: "Diaper Enterprises")).to be_valid
      expect(build(:vendor, business_name: nil)).to_not be_valid
    end
  end

  context "Methods" do
    describe "volume" do
      it "retrieves the amount of product that has been bought from this vendor" do
        vendor = create(:vendor)
        create(:purchase, :with_items, item_quantity: 10, amount_spent_in_cents: 1, vendor: vendor)
        expect(vendor.volume).to eq(10)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end