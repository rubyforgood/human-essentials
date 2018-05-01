# == Schema Information
#
# Table name: items
#
#  id              :integer          not null, primary key
#  name            :string
#  category        :string
#  created_at      :datetime
#  updated_at      :datetime
#  barcode_count   :integer
#  organization_id :integer
#

class Item < ApplicationRecord
  belongs_to :organization # If these are universal this isn't necessary
  belongs_to :canonical_item
  validates_uniqueness_of :name, :scope => :organization
  validates_presence_of :name
  validates :organization, presence: true

  has_many :line_items
  has_many :inventory_items
  has_many :barcode_items
  has_many :storage_locations, through: :inventory_items
  has_many :donations, through: :line_items, source: :itemizable, source_type: Donation
  has_many :distributions, through: :line_items, source: :itemizable, source_type: Distribution

  include Filterable
  scope :alphabetized, -> { order(:name) }
  scope :in_category, ->(category) { where(category: category) }
  scope :in_same_category_as, ->(item) { where(category: item.category).where.not(id: item.id) }

  def self.categories
    select(:category).group(:category).order(:category)
  end

  def self.barcoded_items
    joins(:barcode_items).order(:name).group(:id)
  end

  def self.storage_locations_containing(item)
    StorageLocation.joins(:inventory_items).where('inventory_items.item_id = ?', item.id)
  end

  def self.barcodes_for(item)
    BarcodeItem.where('item_id = ?', item.id)
  end

  # Convenience method so that other methods can be simplified to
  # expect an id or an Item object
  def to_i
    id
  end
end
