# == Schema Information
#
# Table name: items
#
#  id                             :integer          not null, primary key
#  name                           :string
#  category                       :string
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  barcode_count                  :integer
#  organization_id                :integer
#  active                         :boolean          default(TRUE)
#  partner_key                    :string
#  value_in_cents                 :integer          default(0)
#  on_hand_minimum_quantity       :integer          default(0)
#  on_hand_recommended_quantity   :integer
#  package_size                   :integer
#  distribution_quantity          :integer
#

class Item < ApplicationRecord
  belongs_to :organization # If these are universal this isn't necessary
  belongs_to :base_item, counter_cache: :item_count, primary_key: :partner_key, foreign_key: :partner_key, inverse_of: :items
  validates :name, uniqueness: { scope: :organization }
  validates :name, presence: true
  validates :organization, presence: true
  validates :value_in_cents, numericality: { greater_than_or_equal_to: 0 }

  has_many :line_items, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy
  has_many :storage_locations, through: :inventory_items
  has_many :donations, through: :line_items, source: :itemizable, source_type: Donation
  has_many :distributions, through: :line_items, source: :itemizable, source_type: Distribution

  include Filterable
  scope :active, -> { where(active: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_base_item, ->(base_item) { where(base_item: base_item) }
  scope :by_partner_key, ->(partner_key) { where(partner_key: partner_key) }

  scope :by_size, ->(size) { joins(:base_item).where(base_items: { size: size }) }
  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .includes(:base_item)
      .alphabetized
  }

  def self.barcoded_items
    joins(:barcode_items).order(:name).group(:id)
  end

  def self.storage_locations_containing(item)
    StorageLocation.joins(:inventory_items).where("inventory_items.item_id = ?", item.id)
  end

  def self.barcodes_for(item)
    BarcodeItem.where("barcodeable_id = ?", item.id)
  end

  def self.reactivate(item_ids)
    item_ids = Array.wrap(item_ids)
    Item.where(id: item_ids).find_each { |item| item.update(active: true) }
  end

  def other?
    partner_key == "other"
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

  def self.gather_items(current_organization, global = false)
    if global
      where(id: current_organization.barcode_items.all.pluck(:barcodeable_id))
    else
      where(id: current_organization.barcode_items.pluck(:barcodeable_id))
    end
  end
  # Convenience method so that other methods can be simplified to
  # expect an id or an Item object

  def to_i
    id
  end

  def to_h
    { name: name, partner_key: partner_key }
  end

  def self.csv_export_headers
    ["Name", "Barcodes", "Base Item"]
  end

  def csv_export_attributes
    [
      name,
      barcode_count,
      base_item.name
    ]
  end

  def default_quantity
    distribution_quantity || 50
  end
end
