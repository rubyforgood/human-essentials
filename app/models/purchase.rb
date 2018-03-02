# == Schema Information
#
# Table name: purchases
#
#  id                  :integer          not null, primary key
#  purchased_from      :string
#  comment             :text
#  organization_id     :integer
#  storage_location_id :integer
#  amount_spent        :integer
#  issued_at           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Purchase < ApplicationRecord
  belongs_to :organization
  include Itemizable

  include Filterable
  scope :at_storage_location, ->(storage_location_id) { where(storage_location_id: storage_location_id) }
  scope :purchased_from, ->(purchased_from) { where(purchased_from: purchased_from) }

  include IssuedAt

  scope :during, ->(range) { where(purchases: { issued_at: range }) }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }
end
