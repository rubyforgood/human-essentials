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
class PartnerGroupMembership < ApplicationRecord
  belongs_to :partner_group
  belongs_to :partner
  has_one :organization, through: :partner_group

  validates :partner_group, presence: true
  validates :partner, presence: true, uniqueness: { scope: :partner_group }

  validate :partner_belongs_to_partner_group_organization

  private

  def partner_belongs_to_partner_group_organization
    return if organization.nil?

    unless organization == partner.organization
      errors.add :partner, "partner must belong to same organization as partner_group"
    end
  end
end
