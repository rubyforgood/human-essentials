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
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  include Filterable
  scope :barcodeable_id, ->(barcodeable_id) { where(barcodeable_id: barcodeable_id) }
  scope :include_global, ->(global) { where(global: [false, global]) }

  alias_attribute :item, :barcodeable

=begin
  # TODO - BarcodeItems should be able to filter on CanonicalItemId
  def self.canonical_item_id(canonical_item_id)
    items = BarcodeItem.find(:all,
    joins: "INNER JOIN items ON items.canonical_item_id = #{canonical_item_id}",
    )
    canonical_barcode_items = self.where(barcodeable_type: "CanonicalItem", barcodeable_id: canonical_item_id)
    #items = self.joins(:items).where(barcodeable_type: "Item", items: { canonical_item_id: canonical_item_id } )
    (canonical_barcode_items + items).uniq
  end
=end
  # TODO - this should be renamed to something more specific -- it produces a hash, not a line_item object
  def to_h
    {
      barcodeable_id: barcodeable_id,
      barcodeable_type: barcodeable_type,
      quantity: quantity
    }
  end
end
