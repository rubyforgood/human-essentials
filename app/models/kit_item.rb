# == Schema Information
#
# Table name: kit_items
#
#  id         :bigint           not null, primary key
#  quantity   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  item_id    :integer
#  kit_id     :integer
#
class KitItem < ApplicationRecord
  belongs_to :kit
  belongs_to :item

  validates :quantity, presence: true
end
