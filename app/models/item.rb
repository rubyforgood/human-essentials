# == Schema Information
#
# Table name: items
#
#  id         :integer          not null, primary key
#  name       :string
#  category   :string
#  created_at :datetime
#  updated_at :datetime
#

class Item < ActiveRecord::Base
  has_many :containers
  has_many :holdings
  has_many :barcode_items
  has_many :inventories, through: :holdings
  has_many :donations, through: :containers, source: :itemizable, source_type: Donation
  has_many :tickets, through: :containers, source: :itemizable, source_type: Ticket
end
