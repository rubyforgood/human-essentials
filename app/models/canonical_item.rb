# == Schema Information
#
# Table name: canonical_items
#
#  id            :integer          not null, primary key
#  key           :string
#  name          :string
#  barcode_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class CanonicalItem < ApplicationRecord
  has_many :items

  validates_uniqueness_of :name, :key
  validates_presence_of :name, :key
end
