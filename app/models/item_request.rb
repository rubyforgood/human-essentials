# == Schema Information
#
# Table name: item_requests
#
#  id         :bigint(8)        not null, primary key
#  request_id :bigint(8)
#  item_id    :bigint(8)
#  quantity   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class ItemRequest < ApplicationRecord
  belongs_to :request
  belongs_to :item
end
