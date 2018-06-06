# == Schema Information
#
# Table name: canonical_items
#
#  id            :bigint(8)        not null, primary key
#  key           :string
#  name          :string
#  category      :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  size          :string
#

class CanonicalItem < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy, inverse_of: :canonical_items

  validates_presence_of :name, :category
  validates_uniqueness_of :name
end
