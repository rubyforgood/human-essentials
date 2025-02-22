# == Schema Information
#
# Table name: tags
#
#  id              :bigint           not null, primary key
#  name            :string(256)      not null
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint           not null
#
class Tag < ApplicationRecord
  self.inheritance_column = nil

  has_many :taggings, dependent: :destroy
  belongs_to :organization

  scope :alphabetized, -> { order(:name) }
  scope :by_type, ->(type) { where(type: type) }

  validates :name, presence: true, length: {maximum: 256}
  validates :name, uniqueness: {scope: [:type, :organization_id]}
end
