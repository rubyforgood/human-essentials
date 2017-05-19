# == Schema Information
#
# Table name: items
#
#  id            :integer          not null, primary key
#  name          :string
#  category      :string
#  created_at    :datetime
#  updated_at    :datetime
#  barcode_count :integer
#

class Item < ApplicationRecord
  belongs_to :organization # If these are universal this isn't necessary
  validates :name, presence: true, uniqueness: true
  
  has_many :containers
  has_many :holdings
  has_many :barcode_items
  has_many :inventories, through: :holdings
  has_many :donations, through: :containers, source: :itemizable, source_type: Donation
  has_many :tickets, through: :containers, source: :itemizable, source_type: Ticket

  include Filterable
  scope :in_category, ->(category) { where(category: category) }
  scope :in_same_category_as, ->(item) { where(category: item.category).where.not(id: item.id) }

  def self.categories
    self.select(:category).group(:category)
  end

  def self.inventories_containing(item)
    Inventory.joins(:holdings).where('holdings.item_id = ?', item.id)
  end

  def self.barcodes_for(item)
    BarcodeItem.where('item_id = ?', item.id)
  end
end
