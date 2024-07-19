RSpec.describe PurchasesHelper, type: :helper do
  describe "#new_purchase_default_location" do
    helper do
      def current_organization
      end
    end

    context "returns purchase storage_location_id if present" do
      let(:purchase) { build(:purchase, storage_location_id: 2) }
      subject { helper.new_purchase_default_location(purchase) }

      it { is_expected.to eq(2) }
    end

    context "returns current_organization intake_location if purchase storage_location_id is not present" do
      let(:organization) { build(:organization, intake_location: 1) }
      let(:purchase) { build(:purchase, storage_location_id: nil) }

      before do
        allow(helper).to receive(:current_organization).and_return(organization)
      end

      subject { helper.new_purchase_default_location(purchase) }

      it { is_expected.to eq(1) }
    end
  end
end
