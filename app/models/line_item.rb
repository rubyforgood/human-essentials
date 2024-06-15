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
  validates :quantity, numericality: { only_integer: true, message: "is not a number. Note: commas are not allowed" }
  validate :quantity_must_be_a_number_within_range

  scope :active, -> { joins(:item).where(items: { active: true }) }

  delegate :name, to: :item

  def quantity_must_be_a_number_within_range
    if quantity && quantity > MAX_INT
      errors.add(:quantity, "must be less than #{MAX_INT}")
    elsif quantity && quantity < MIN_INT
      errors.add(:quantity, "must be greater than #{MIN_INT}")
    end
  end
end
