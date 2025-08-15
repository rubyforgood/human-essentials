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

  validates :quantity, numericality: { only_integer: true, message: "is not a number. Note: commas are not allowed" }
  validate :quantity_must_be_a_number_within_range

  scope :active, -> { joins(:item).where(items: { active: true }) }

  scope :inventory_in_storage, ->(storage_location_id) do
    joins("
      LEFT OUTER JOIN donations ON donations.id = line_items.itemizable_id AND line_items.itemizable_type = 'Donation'
      LEFT OUTER JOIN purchases ON purchases.id = line_items.itemizable_id AND line_items.itemizable_type = 'Purchase'
      LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
      LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
      .where("donations.storage_location_id = :storage_location_id OR
              purchases.storage_location_id = :storage_location_id OR
              (adjustments.storage_location_id = :storage_location_id and line_items.quantity < 0) OR
              transfers.to_id = :storage_location_id", storage_location_id: storage_location_id)
  end

  scope :inventory_out_storage, ->(storage_location_id) do
    joins("
      LEFT OUTER JOIN distributions ON distributions.id = line_items.itemizable_id AND line_items.itemizable_type = 'Distribution'
      LEFT OUTER JOIN adjustments ON adjustments.id = line_items.itemizable_id AND line_items.itemizable_type = 'Adjustment'
      LEFT OUTER JOIN transfers ON transfers.id = line_items.itemizable_id AND line_items.itemizable_type = 'Transfer'")
      .where("distributions.storage_location_id = :storage_location_id OR
              (adjustments.storage_location_id = :storage_location_id and line_items.quantity > 0) OR
              transfers.from_id = :storage_location_id", storage_location_id: storage_location_id)
  end

  delegate :name, to: :item

  # Used in a distribution that was initialized from a request. The `item_request` will be
  # populated here.
  attr_accessor :requested_item

  def quantity_must_be_a_number_within_range
    if quantity && quantity > MAX_INT
      errors.add(:quantity, "must be less than #{MAX_INT}")
    elsif quantity && quantity < MIN_INT
      errors.add(:quantity, "must be greater than #{MIN_INT}")
    end
  end
end
