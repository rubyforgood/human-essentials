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
  has_many :items
  has_many :barcode_items, as: :barcodeable

  validates_uniqueness_of :name, :key
  validates_presence_of :name, :key

  def to_key
    name.tr(" ","_").gsub(/[^A-Za-z]/,'').downcase
  end
end
