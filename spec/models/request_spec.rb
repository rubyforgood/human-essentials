# == Schema Information
#
# Table name: requests
#
#  id              :bigint           not null, primary key
#  comments        :text
#  request_items   :jsonb
#  status          :integer          default("pending")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  distribution_id :integer
#  organization_id :bigint
#  partner_id      :bigint
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

  describe "total_items" do
    let(:request) { create(:request, request_items: [{ item_id: Item.active.first.id, quantity: 15 }, { item_id: Item.active.last.id, quantity: 18 }]) }

    it "adds the quantity of all items in the request" do
      expect(request.total_items).to eq(33)
    end
  end
end
