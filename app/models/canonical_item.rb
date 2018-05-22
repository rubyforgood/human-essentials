# == Schema Information
#
# Table name: canonical_items
#
#  id            :integer          not null, primary key
#  key           :string
#  name          :string
#  category      :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class CanonicalItem < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy, inverse_of: :canonical_items

  validates :name, :key, uniqueness: true
  validates :name, :key, presence: true

  def to_key
    name.tr(" ", "_").gsub(/[^A-Za-z]/, "").downcase
  end
end
