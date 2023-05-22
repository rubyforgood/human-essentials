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
  include ItemQuantity
  MAX_INT = 2**31
  MIN_INT = -2**31

  # To any future developers:
  # WARNING, WARNING!!!
  # The code that handles Distribution updates (and, soon, the code that handles Purchase and Donation updates)
  # is dependent on the lack of callbacks on LineItem.   Do not add any without thoroughly understanding the
  # implications on the behaviour around all Itemizables.
  # Thanks,  past CL Fisher (2023/05/22)

  belongs_to :itemizable, polymorphic: true, inverse_of: :line_items, optional: false
  belongs_to :item

  validates :item_id, presence: true
  validates :quantity, numericality: { only_integer: true, less_than: MAX_INT, greater_than: MIN_INT }
  scope :active, -> { joins(:item).where(items: { active: true }) }

  delegate :name, to: :item
end
