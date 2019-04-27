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
end
