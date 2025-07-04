# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
class ItemCategory < ApplicationRecord
  has_paper_trail
  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :description, length: { maximum: 250 }

  belongs_to :organization
  has_many :items, -> { order(name: :asc) }, inverse_of: :item_category, dependent: :nullify
  has_and_belongs_to_many :partner_groups, dependent: :nullify

  before_destroy :ensure_no_associated_partner_groups

  private

  def ensure_no_associated_partner_groups
    if partner_groups.exists?
      errors.add(:base, "Cannot delete item category with associated partner groups")
      throw(:abort)
    end
  end
end
