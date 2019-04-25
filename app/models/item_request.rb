class ItemRequest < ApplicationRecord
  belongs_to :request
  belongs_to :item
end
