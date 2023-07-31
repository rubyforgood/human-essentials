# == Schema Information
#
# Table name: line_items
#
#  id              :integer          not null, primary key
#  itemizable_type :string
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  item_id         :integer
#  itemizable_id   :integer
#

class LineItem < ApplicationRecord
  has_paper_trail
  include ItemQuantity
  MAX_INT = 2**31
  MIN_INT = -2**31

  belongs_to :itemizable, polymorphic: true, inverse_of: :line_items, optional: false
  belongs_to :item

  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, less_than: MAX_INT, greater_than: MIN_INT }
  scope :active, -> { joins(:item).where(items: { active: true }) }
  scope :out_items, -> (storage_location_id, organization_id) { where("(distributions.storage_location_id = :id or (adjustments.storage_location_id= :id and line_items.quantity < 0) or transfers.from_id = :id or kit_allocations.storage_location_id = :id) and items.organization_id= :organization_id", id: storage_location_id, organization_id: organization_id) }
  scope :in_items, -> (storage_location_id, organization_id) { where("(donations.storage_location_id = :id or purchases.storage_location_id = :id or (adjustments.storage_location_id = :id and line_items.quantity > 0) or transfers.to_id = :id or kit_allocations.storage_location_id = :id)  and items.organization_id = :organization_id", id: storage_location_id, organization_id: organization_id) }
  delegate :name, to: :item
end
