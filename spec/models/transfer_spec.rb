# == Schema Information
#
# Table name: transfers
#
#  id              :integer          not null, primary key
#  from_id         :integer
#  to_id           :integer
#  comment         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

RSpec.describe Transfer, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:transfer, organization_id: nil)).not_to be_valid
    end
  end
end
