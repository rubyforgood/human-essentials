# == Schema Information
#
# Table name: barcode_items
#
#  id               :bigint(8)        not null, primary key
#  value            :string
#  barcodeable_id   :integer
#  quantity         :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  organization_id  :integer
#  global           :boolean          default(FALSE)
#  barcodeable_type :string           default("Item")
#

class BarcodeItem < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :barcodeable, polymorphic: true, dependent: :destroy, counter_cache: :barcode_count

  # These two methods are used by the scopes `by_item_partner_key` and `by_canonical_item_partner_key` #
  # rubocop:disable Rails/InverseOf
  belongs_to :item, -> { where(barcode_items: { barcodeable_type: 'Item' }) }, foreign_key: 'barcodeable_id'
  belongs_to :canonical_item, -> { where(barcode_items: { barcodeable_type: 'CanonicalItem' }) }, foreign_key: 'barcodeable_id'
  # rubocop:enable Rails/InverseOf
  def item
    return unless barcodeable_type == "Item"

    super
  end

  def canonical_item
    return unless barcodeable_type == "CanonicalItem"

    super
  end
  #######################################################################################################

  validates :organization, presence: true, unless: proc { |b| b.global? }
  validates :value, presence: true
  validate  :unique_barcode_value
  validates :quantity, :barcodeable, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  include Filterable
  default_scope { order("global ASC, created_at ASC") }

  scope :barcodeable_id, ->(barcodeable_id) { where(barcodeable_id: barcodeable_id) }
  scope :by_item_partner_key, ->(partner_key) { joins(:item).where(items: { partner_key: partner_key }) }
  scope :by_canonical_item_partner_key, ->(partner_key) { joins(:canonical_item).where(canonical_items: { partner_key: partner_key }) }
  scope :by_value,       ->(value) { where(value: value) }
  scope :include_global, ->(global) { where(global: [false, global]) }
  scope :for_csv_export, ->(organization) {
    where(organization: organization)
      .includes(:barcodeable)
  }
  scope :global, -> { where(global: true) }

  alias_attribute :item, :barcodeable
  alias_attribute :canonical_item, :barcodeable

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

  private

  def unique_barcode_value
    if (global? && BarcodeItem.where.not(id: id).find_by(value: value, global: true)) ||
       (!global? && BarcodeItem.where.not(id: id).find_by(value: value, organization: organization))
      errors.add(:value, "That barcode value already exists")
    end
  end
end
