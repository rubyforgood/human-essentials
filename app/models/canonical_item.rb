# == Schema Information
#
# Table name: canonical_items
#
#  id            :bigint(8)        not null, primary key
#  name          :string
#  category      :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  size          :string
#  item_count    :integer
#

class CanonicalItem < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy, inverse_of: :canonical_items

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true
end
