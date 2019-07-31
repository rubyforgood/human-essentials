# == Schema Information
#
# Table name: line_items
#
#  id              :integer          not null, primary key
#  quantity        :integer
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class LineItem < ApplicationRecord
  MAX_INT = 2**31
  MIN_INT = -2**31

  belongs_to :itemizable, polymorphic: true, inverse_of: :line_items, optional: false
  belongs_to :item

  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, less_than: MAX_INT, greater_than: MIN_INT }
  scope :active, -> { joins(:item).where(items: { active: true }) }

  # FIXME: This is a temporary hack to stop a 500 from showing up. We need to remove the default_scope from Item
  def value_per_line_item
    (item&.value_in_cents || 0) * quantity
  end

  def has_packages
    quantity / item.package_size.to_f if item.package_size
  end

  def package_count
    format("%g", has_packages) if has_packages
  end
end
