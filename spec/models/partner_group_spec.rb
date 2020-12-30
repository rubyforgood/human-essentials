# == Schema Information
#
# Table name: partner_groups
#
#  id              :bigint           not null, primary key
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
RSpec.describe PartnerGroup, type: :model do
  context "Validations >" do
    it "must belong to an organization" do
      expect(build(:partner_group, organization_id: nil)).not_to be_valid
    end

    it "requires a unique name within an organization" do
      expect(build(:partner_group, name: nil)).not_to be_valid
      create(:partner_group, name: "Foo")
      expect(build(:partner_group, name: "Foo")).not_to be_valid
    end

    it "does not require a unique name between organizations" do
      create(:partner, name: "Foo")
      expect(build(:partner, name: "Foo", organization: build(:organization))).to be_valid
    end
  end
end
