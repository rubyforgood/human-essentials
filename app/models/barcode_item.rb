# == Schema Information
#
# Table name: barcode_items
#
#  id               :integer          not null, primary key
#  barcodeable_type :string           default("Item")
#  quantity         :integer
#  value            :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  barcodeable_id   :integer
#  organization_id  :integer
#

class BarcodeItem < ApplicationRecord
  has_paper_trail
  belongs_to :organization, optional: true
  belongs_to :barcodeable, polymorphic: true, dependent: :destroy, counter_cache: :barcode_count

  validates :organization, presence: true, unless: proc { |b| b.barcodeable_type == "BaseItem" }
  validates :value, presence: true
  validate  :unique_barcode_value
  validates :quantity, :barcodeable, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  include Filterable
  include Exportable
  default_scope { order("barcodeable_type DESC, created_at ASC") }

  scope :barcodeable_id, ->(barcodeable_id) { where(barcodeable_id: barcodeable_id) }

  # Because it's a polymorphic association, we have to do this join manually.
  scope :by_item_partner_key, ->(partner_key) do
    joins("INNER JOIN items ON items.id = barcode_items.barcodeable_id")
      .where(barcodeable_type: "Item", items: { partner_key: partner_key })
  end

  scope :by_base_item_partner_key, ->(partner_key) do
    joins("INNER JOIN base_items ON base_items.id = barcode_items.barcodeable_id")
      .where(barcodeable_type: "BaseItem", base_items: { partner_key: partner_key })
  end

  scope :by_value, ->(value) { where(value: value) }

  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .includes(:barcodeable)
  }

  scope :global, -> { where(barcodeable_type: "BaseItem") }

  alias_attribute :item, :barcodeable
  alias_attribute :base_item, :barcodeable

  def to_h
    {
      barcodeable_id: barcodeable_id,
      barcodeable_type: barcodeable_type,
      quantity: quantity
    }
  end

  def self.csv_export_headers
    ["Item Type", "Quantity in the Box", "Barcode"]
  end

  def csv_export_attributes
    [
      barcodeable.name,
      quantity,
      value
    ]
  end

  def global?
    barcodeable_type == "BaseItem"
  end

  private

  def unique_barcode_value
    if (global?  && BarcodeItem.where.not(id: id).find_by(value: value, barcodeable_type: "BaseItem")) ||
       (!global? && BarcodeItem.where.not(id: id).find_by(value: value, organization:     organization))
      errors.add(:value, "That barcode value already exists")
    end
  end
end
