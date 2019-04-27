# == Schema Information
#
# Table name: requests
#
#  id              :bigint(8)        not null, primary key
#  partner_id      :bigint(8)
#  organization_id :bigint(8)
#  status          :string           default("Active")
#  request_items   :jsonb
#  comments        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  distribution_id :integer
#

RSpec.describe Request, type: :model do
  describe "Scopes >" do
    describe "->active" do
      it "retrieves only those with active status" do
        Request.delete_all
        create(:request, status: "Fulfilled")
        create(:request, status: "Active")
        expect(Request.active.size).to eq(1)
      end
    end
  end

  describe "Methods >" do
    describe "items_hash" do
      it "retrieves a hash that materializes the items from the JSONB" do
        c1, c2 = BaseItem.all.take(2)
        request = create(:request, request_items:
            [{ "item_id" => c1.items.first.id, "quantity" => 10},
             { "item_id" => c2.items.first.id, "quantity" => 10}])

        items_hash = request.items_hash
        expect(items_hash.keys).to match_array([c1.items.first.partner_key, c2.items.first.partner_key])
        expect(items_hash.values).to match_array([c1.items.first, c2.items.first])
      end
    end
  end
end
