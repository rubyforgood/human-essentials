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
  validate :validate_quantity_for_kit
  scope :active, -> { joins(:item).where(items: { active: true }) }

  delegate :name, to: :item

  private

  def validate_quantity_for_kit
    if itemizable_type == "Kit" && quantity.negative?
      errors.add(:quantity, "must be a positive number")
    end
  end
end
