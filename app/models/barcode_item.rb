# == Schema Information
#
# Table name: barcode_items
#
#  id               :integer          not null, primary key
#  value            :string
#  barcodeable_id   :integer
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organization_id  :integer
#  global           :boolean          default(FALSE)
#  barcodeable_type :string           default("Item")
#

class BarcodeItem < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :barcodeable, polymorphic: true, dependent: :destroy, counter_cache: :barcode_count

  validates :value, presence: true, uniqueness: true
  validates :quantity, :barcodeable, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  include Filterable
  scope :barcodeable_id, ->(barcodeable_id) { where(barcodeable_id: barcodeable_id) }
  scope :only_global, ->(global) { where(global: true) if global }

  # TODO - this should be renamed to something more specific -- it produces a hash, not a line_item object
  def to_h
    {
      barcodeable_id: barcodeable.id,
      quantity: quantity
    }
  end
end
