# == Schema Information
#
# Table name: barcode_items
#
#  id         :integer          not null, primary key
#  value      :string
#  item_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  quantity   :integer
#

class BarcodeItem < ActiveRecord::Base
  belongs_to :item, dependent: :destroy, counter_cache: :barcode_count

  validates :value, presence: true, uniqueness: true
  validates :quantity, presence: true
  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0}

  def to_container
    {
      item_id: item.id,
      quantity: quantity
    }
  end
end
