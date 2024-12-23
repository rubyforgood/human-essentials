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

  scope :alphabetized, -> { order(:name) }

  validates :name, presence: true, length: {maximum: 256}
end
