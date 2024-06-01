# == Schema Information
#
# Table name: requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  discard_reason  :text
#  discarded_at    :datetime
#  request_items   :jsonb
#  status          :integer          default("pending")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  distribution_id :integer
#  organization_id :bigint
#  partner_id      :bigint
#  partner_user_id :integer
#

RSpec.describe Request, type: :model do
  describe "Enums >" do
    describe "#status" do
      let!(:request_pending) { create(:request) }
      let!(:request_started) { create(:request, :started) }
      let!(:request_fulfilled) { create(:request, :fulfilled) }

      it "scopes" do
        expect(Request.status_pending).to eq([request_pending])
        expect(Request.status_started).to eq([request_started])
        expect(Request.status_fulfilled).to eq([request_fulfilled])
      end
    end
  end

  describe "item data" do
    it "coerces item quantity and id to always be an integer before saving" do
      request = create(:request,
                       partner_user: ::User.partner_users.first,
                       request_items: [
                         { item_id: "25", quantity: "15" },
                         { item_id: "35", quantity: 18 }
                       ])
      expect(request.request_items.first["item_id"]).to be 25
      expect(request.request_items.first["quantity"]).to be 15
      expect(request.request_items.last["item_id"]).to be 35
      expect(request.request_items.last["quantity"]).to be 18
    end
  end

  describe "total_items" do
    let(:id_one) { create(:item).id }
    let(:id_two) { create(:item).id }
    let(:request) { create(:request, request_items: [{ item_id: id_one, quantity: 15 }, { item_id: id_two, quantity: 18 }]) }

    it "adds the quantity of all items in the request" do
      expect(request.total_items).to eq(33)
    end
  end

  describe "validations" do
    let(:item_one) { create(:item) }
    let(:item_two) { create(:item) }
    subject { build(:request, item_requests: item_requests) }

    context "when item_requests have unique item_ids" do
      let(:item_requests) do
        [
          create(:item_request, item: item_one, quantity: 5),
          create(:item_request, item: item_two, quantity: 3)
        ]
      end

      it "is valid" do
        expect(subject).to be_valid
      end
    end

    context "when item_requests do not have unique item_ids" do
      let(:item_requests) do
        [
          create(:item_request, item: item_one, quantity: 5),
          create(:item_request, item: item_one, quantity: 3)
        ]
      end

      it "is not valid" do
        expect(subject).to_not be_valid
        expect(subject.errors[:item_requests]).to include("should have unique item_ids")
      end
    end
  end

  describe "versioning" do
    it { is_expected.to be_versioned }
  end
end
