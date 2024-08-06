# == Schema Information
#
# Table name: items
#
#  id                           :integer          not null, primary key
#  active                       :boolean          default(TRUE)
#  barcode_count                :integer
#  category                     :string
#  distribution_quantity        :integer
#  name                         :string
#  on_hand_minimum_quantity     :integer          default(0), not null
#  on_hand_recommended_quantity :integer
#  package_size                 :integer
#  partner_key                  :string
#  value_in_cents               :integer          default(0)
#  visible_to_partners          :boolean          default(TRUE), not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  item_category_id             :integer
#  kit_id                       :integer
#  organization_id              :integer
#

class Item < ApplicationRecord
  has_paper_trail
  include Filterable
  include Exportable
  include Valuable

  after_update :update_associated_kit_name, if: -> { kit.present? }

  belongs_to :organization # If these are universal this isn't necessary
  belongs_to :base_item, counter_cache: :item_count, primary_key: :partner_key, foreign_key: :partner_key, inverse_of: :items
  belongs_to :kit, optional: true
  belongs_to :item_category, optional: true

  validates :name, uniqueness: { scope: :organization, case_sensitive: false, message: "- An item with that name already exists (could be an inactive item)" }
  validates :name, presence: true
  validates :organization, presence: true
  validates :distribution_quantity, numericality: { greater_than: 0 }, allow_blank: true
  validates :on_hand_recommended_quantity, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :on_hand_minimum_quantity, numericality: { greater_than_or_equal_to: 0 }

  has_many :line_items, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :barcode_items, as: :barcodeable, dependent: :destroy
  has_many :storage_locations, through: :inventory_items
  has_many :donations, through: :line_items, source: :itemizable, source_type: "::Donation"
  has_many :distributions, through: :line_items, source: :itemizable, source_type: "::Distribution"
  has_many :request_units, class_name: "ItemUnit", dependent: :destroy

  scope :active, -> { where(active: true) }

  # Add spec for these
  scope :kits, -> { where.not(kit_id: nil) }
  scope :loose, -> { where(kit_id: nil) }

  scope :visible, -> { where(visible_to_partners: true) }
  scope :alphabetized, -> { order(:name) }
  scope :by_base_item, ->(base_item) { where(base_item: base_item) }
  scope :by_partner_key, ->(partner_key) { where(partner_key: partner_key) }

  scope :by_size, ->(size) { joins(:base_item).where(base_items: { size: size }) }
  scope :for_csv_export, ->(organization, *) {
    where(organization: organization)
      .includes(:base_item)
      .alphabetized
  }

  # Scopes - explanation of business rules for filtering scopes as of 20240527.  This was a mess, but is much better now.
  # 1/  Disposable.   Disposables are only the disposable diapers for children.  So we deliberately exclude adult and cloth
  # 2/  Cloth.  Cloth diapers for children.  Exclude adult cloth. Cloth training pants also go here.
  # 3/  Adult incontinence.  Items for adult incontinence -- diapers, ai pads, but not adult wipes.
  # 4/  Period supplies.  All things with 'menstrual in the category'
  # 5/  Other -- Miscellaneous, and wipes
  # Known holes and ambiguities as of 20240527.  Working on these with the business
  # 1/  Liners.   We are adding a new item for AI liners,  and renaming the current liners to be specficially for periods,
  # having confirmed with the business that the majority of liners are for menstrual use.
  # However, there is a product which can be used for either, so we are still sussing out what to do about that.

  scope :disposable, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%diaper%'")
      .where.not("lower(base_items.category) LIKE '%cloth%' OR lower(base_items.name) LIKE '%cloth%'")
      .where.not("lower(base_items.category) LIKE '%adult%'")
  }

  scope :cloth_diapers, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%cloth%'")
      .or(where("base_items.category = 'Training Pants'"))
      .where.not("lower(base_items.category) LIKE '%adult%'")
  }

  scope :adult_incontinence, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%adult%' AND lower(base_items.category) NOT LIKE '%wipes%'")
  }

  scope :period_supplies, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%menstrual%'")
  }

  scope :other_categories, -> {
    joins(:base_item)
      .where("lower(base_items.category) LIKE '%wipes%'")
      .or(where("base_items.category = 'Miscellaneous'"))
  }

  before_destroy :validate_destroy, prepend: true

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

  def has_inventory?(inventory = nil)
    if inventory
      inventory.quantity_for(item_id: id).positive?
    else
      inventory_items.where("quantity > 0").any?
    end
  end

  def is_in_kit?(kits = nil)
    if kits
      kits.any? { |k| k.line_items.map(&:item_id).include?(id) }
    else
      organization.kits
        .active
        .joins(:line_items)
        .where(line_items: { item_id: id}).any?
    end
  end

  def can_delete?(inventory = nil, kits = nil)
    can_deactivate_or_delete?(inventory, kits) && line_items.none? && !barcode_count&.positive?
  end

  # @return [Boolean]
  def can_deactivate_or_delete?(inventory = nil, kits = nil)
    if inventory.nil? && Event.read_events?(organization)
      inventory = View::Inventory.new(organization_id)
    end
    # Cannot deactivate if it's currently in inventory in a storage location. It doesn't make sense
    # to have physical inventory of something we're now saying isn't valid.
    # If an active kit includes this item, then changing kit allocations would change inventory
    # for an inactive item - which we said above we don't want to allow.

    !has_inventory?(inventory) && !is_in_kit?(kits)
  end

  def validate_destroy
    unless can_delete?
      errors.add(:base, "Cannot delete item - it has already been used!")
      throw(:abort)
    end
  end

  def deactivate!
    unless can_deactivate_or_delete?
      raise "Cannot deactivate item - it is in a storage location or kit!"
    end
    if kit
      kit.deactivate
    else
      update!(active: false)
    end
  end

  def other?
    partner_key == "other"
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
    { name: name, item_id: id }
  end

  def self.csv_export_headers
    ["Name", "Barcodes", "Base Item", "Quantity"]
  end

  # TODO remove this method once read_events? is true everywhere
  def csv_export_attributes
    [
      name,
      barcode_count,
      base_item.name,
      inventory_items.sum(&:quantity)
    ]
  end

  # @param items [Array<Item>]
  # @param inventory [View::Inventory]
  # @return [String]
  def self.generate_csv_from_inventory(items, inventory)
    item_quantities = items.to_h { |i| [i.id, inventory.quantity_for(item_id: i.id)] }
    CSV.generate(headers: true) do |csv|
      csv_data = items.map do |item|
        attributes = [item.name, item.barcode_count, item.base_item.name, item_quantities[item.id]]
        attributes.map { |attr| normalize_csv_attribute(attr) }
      end
      ([csv_export_headers] + csv_data).each { |row| csv << row }
    end
  end

  def default_quantity
    distribution_quantity || 50
  end

  def inventory_item_at(storage_location_id)
    inventory_items.find_by(storage_location_id: storage_location_id)
  end

  def sync_request_units!(unit_ids)
    request_units.clear
    organization.request_units.where(id: unit_ids).pluck(:name).each do |name|
      request_units.create!(name:)
    end
  end

  private

  def update_associated_kit_name
    kit.update(name: name)
  end
end
