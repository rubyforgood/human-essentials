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
  belongs_to :storage_location

  include Itemizable
  include Filterable
  include IssuedAt

  scope :at_storage_location, ->(storage_location_id) { where(storage_location_id: storage_location_id) }
  scope :purchased_from, ->(purchased_from) { where(purchased_from: purchased_from) }
  scope :during, ->(range) { where(purchases: { issued_at: range }) }
  scope :recent, ->(count = 3) { order(issued_at: :desc).limit(count) }

  before_create :combine_duplicates
  before_destroy :remove_inventory

  validates_numericality_of :amount_spent, greater_than: 0

  def storage_view
    storage_location.nil? ? "N/A" : storage_location.name
  end

  def remove_inventory
    storage_location.remove!(self)
  end

  private
  def combine_duplicates
    Rails.logger.info "Combining!"
    self.line_items.combine!
  end
end
