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
  validates :organization, presence: true
  validates :description, length: { maximum: 250 }

  belongs_to :organization
  has_many :items, -> { order(name: :asc) }, inverse_of: :item_category, dependent: :nullify
  has_many :partner_groups, dependent: :nullify
end
