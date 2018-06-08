# == Schema Information
#
# Table name: line_items
#
#  id              :bigint(8)        not null, primary key
#  quantity        :integer
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class LineItem < ApplicationRecord
  belongs_to :itemizable, polymorphic: true, inverse_of: :line_items, required: true
  belongs_to :item

  validates :item_id, presence: true
  validates :quantity, numericality: { other_than: 0, only_integer: true }
end
