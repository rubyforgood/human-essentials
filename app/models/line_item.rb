# == Schema Information
#
# Table name: line_items
#
#  id              :integer          not null, primary key
#  quantity        :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  item_id         :integer
#  itemizable_id   :integer
#  itemizable_type :string
#

class LineItem < ApplicationRecord
  belongs_to :itemizable, polymorphic: true, inverse_of: :line_items, required: true
  belongs_to :item

  validates :item_id, presence: true
  validates :quantity, presence: true
end
