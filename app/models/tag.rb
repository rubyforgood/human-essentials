# == Schema Information
#
# Table name: tags
#
#  id         :bigint           not null, primary key
#  name       :string(256)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy

  validates :name, presence: true
  validates_length_of :name, maximum: 255

  scope :for_taggable, ->(taggable) {
    joins(:taggings)
      .where(taggings: taggable)
      .where(taggings: { organization_id: taggable.organization_id })
      .select("DISTINCT tags.*")
  }
end
