# == Schema Information
#
# Table name: vendors
#
#  id              :bigint           not null, primary key
#  active          :boolean          default(TRUE)
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

  context "Scopes" do
    describe "with_volumes" do
      subject { described_class.with_volumes }

      it "retrieves the amount of product that has been bought from this vendor" do
        vendor = create(:vendor)
        create(:purchase, :with_items, item_quantity: 10, amount_spent_in_cents: 1, vendor: vendor)

        expect(subject.first.volume).to eq(10)
      end
    end

    describe "deactivate!" do
      it "deactivates the vendor" do
        vendor = create(:vendor)
        vendor.deactivate!
        expect(vendor.active).to be(false)
      end
    end

    describe "reactivate!" do
      it "reactivates the vendor" do
        vendor = create(:vendor, active: false)
        vendor.reactivate!
        expect(vendor.active).to be(true)
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
