# == Schema Information
#
# Table name: item_categories
#
#  id              :bigint           not null, primary key
#  description     :text
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer          not null
#
class ItemCategory < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :organization, presence: true
  validates :description, length: { maximum: 250 }

  belongs_to :organization
  has_many :items, -> { order(name: :asc) }
end
