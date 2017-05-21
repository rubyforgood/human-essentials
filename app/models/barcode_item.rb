# == Schema Information
#
# Table name: barcode_items
#
#  id              :integer          not null, primary key
#  value           :string
#  item_id         :integer
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :integer
#

class BarcodeItem < ApplicationRecord
  belongs_to :organization
  belongs_to :item, dependent: :destroy, counter_cache: :barcode_count

  validates :value, presence: true, uniqueness: true
  validates :quantity, :item, :organization, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  include Filterable
  scope :item_id, ->(item_id) { where(item_id: item_id) }

  # TODO - this should be renamed to something more specific -- it produces a hash, not a line_item object
  def to_line_item
    {
      item_id: item.id,
      quantity: quantity
    }
  end
end
