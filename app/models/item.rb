# == Schema Information
#
# Table name: items
#
#  id                :bigint(8)        not null, primary key
#  name              :string
#  category          :string
#  created_at        :datetime
#  updated_at        :datetime
#  barcode_count     :integer
#  organization_id   :integer
#  canonical_item_id :integer
#  active            :boolean          default(TRUE)
#

class Item < ApplicationRecord
  belongs_to :organization # If these are universal this isn't necessary
  belongs_to :canonical_item, counter_cache: :item_count
  validates :name, uniqueness: { scope: :organization }
  validates :name, presence: true
  validates :organization, presence: true

  has_many :line_items
  has_many :inventory_items
  has_many :barcode_items, as: :barcodeable
  has_many :storage_locations, through: :inventory_items
  has_many :donations, through: :line_items, source: :itemizable, source_type: Donation
  has_many :distributions, through: :line_items, source: :itemizable, source_type: Distribution

  include Filterable
  scope :active, -> { where(active: true) }
  scope :alphabetized, -> { order(:name) }
  scope :in_category, ->(category) { where(category: category) }
  scope :by_canonical_item, ->(canonical_item) { where(canonical_item: canonical_item) }
  scope :in_same_category_as, ->(item) { where(category: item.category).where.not(id: item.id) }

  scope :by_size, ->(size) { joins(:canonical_item).where(canonical_items: { size: size }) }

  default_scope { active }

  include DiaperPartnerClient
  after_create :update_diaper_partner

  def self.categories
    select(:category).group(:category).order(:category)
  end

  def self.barcoded_items
    joins(:barcode_items).order(:name).group(:id)
  end

  def self.storage_locations_containing(item)
    StorageLocation.joins(:inventory_items).where("inventory_items.item_id = ?", item.id)
  end

  def self.barcodes_for(item)
    BarcodeItem.where("barcodeable_id = ?", item.id)
  end

  # Override `destroy` to ensure Item isn't accidentally destroyed
  # without first being disassociated with its historical presence
  def destroy
    if has_history?
      update(active: false)
    else
      super
    end
  end

  def has_history?
    !(line_items.empty? && inventory_items.empty? && barcode_items.empty?)
  end

  def self.gather_items(current_organization, global)
    if global
      where(id: current_organization.barcode_items.include_global(false).pluck(:barcodeable_id))
        .merge(where(id: BarcodeItem.where(global: true)))
    else
      where(id: current_organization.barcode_items.include_global(false).pluck(:barcodeable_id))
    end
  end
  # Convenience method so that other methods can be simplified to
  # expect an id or an Item object

  def to_i
    id
  end

  private

  def update_diaper_partner
    DiaperPartnerClient.post "/items", attributes
  end
end
