# == Schema Information
#
# Table name: barcode_items
#
#  id               :bigint(8)        not null, primary key
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

  validates :organization, presence: true, if: proc { |b| b.barcodeable_type == "Item" }
  validates :value, presence: true, uniqueness: true
  validates :quantity, :barcodeable, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  include Filterable
  scope :barcodeable_id, ->(barcodeable_id) { where(barcodeable_id: barcodeable_id) }
  scope :include_global, ->(global) { where(global: [false, global]) }

  alias_attribute :item, :barcodeable

  def to_h
    {
      barcodeable_id: barcodeable_id,
      barcodeable_type: barcodeable_type,
      quantity: quantity
    }
  end
end
