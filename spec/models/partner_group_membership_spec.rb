# == Schema Information
#
# Table name: partner_group_memberships
#
#  id               :bigint           not null, primary key
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  partner_group_id :bigint
#  partner_id       :bigint
#
RSpec.describe PartnerGroupMembership, type: :model do
  context "Validations >" do
    it "must belong to a partner_group" do
      expect(build(:partner_group_membership, partner_group_id: nil)).not_to be_valid
    end

    it "must belong to a partner" do
      expect(build(:partner_group_membership, partner_id: nil)).not_to be_valid
    end

    it "a partner can only be a member of a partner_group once" do
      membership = create(:partner_group_membership)
      expect(build(:partner_group_membership,
                   partner_group: membership.partner_group,
                   partner: membership.partner)).not_to be_valid
    end

    it "a partner must belong to the same organization as the partner_group" do
      partner_group = create(:partner_group, organization: create(:organization))
      partner = create(:partner, organization: create(:organization))
      expect(build(:partner_group_membership,
                   partner_group: partner_group,
                   partner: partner)).not_to be_valid
    end
  end
end
